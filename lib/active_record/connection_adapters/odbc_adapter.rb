require 'active_record'
require 'odbc'
require 'odbc_utf8'

require 'odbc_adapter/database_limits'
require 'odbc_adapter/database_statements'
require 'odbc_adapter/error'
require 'odbc_adapter/quoting'
require 'odbc_adapter/schema_statements'

require 'odbc_adapter/column'
require 'odbc_adapter/column_metadata'
require 'odbc_adapter/database_metadata'
require 'odbc_adapter/registry'
require 'odbc_adapter/version'

require 'odbc_adapter/type/type'

module ActiveRecord
  class Base
    class << self
      # Build a new ODBC connection with the given configuration.
      def odbc_connection(config)
        config = config.symbolize_keys

        connection, config =
          if config.key?(:dsn)
            odbc_dsn_connection(config)
          elsif config.key?(:conn_str)
            odbc_conn_str_connection(config)
          else
            raise ArgumentError, 'No data source name (:dsn) or connection string (:conn_str) specified.'
          end

        database_metadata = ::ODBCAdapter::DatabaseMetadata.new(connection, config[:encoding_bug])
        database_metadata.adapter_class.new(connection, logger, config, database_metadata)
      end

      private

      # Connect using a predefined DSN.
      def odbc_dsn_connection(config)
        username   = config[:username] ? config[:username].to_s : nil
        password   = config[:password] ? config[:password].to_s : nil
        odbc_module = config[:encoding] == 'utf8' ? ODBC_UTF8 : ODBC
        connection = odbc_module.connect(config[:dsn], username, password)

        # encoding_bug indicates that the driver is using non ASCII and has the issue referenced here https://github.com/larskanis/ruby-odbc/issues/2
        [connection, config.merge(username: username, password: password, encoding_bug: config[:encoding] == 'utf8')]
      end

      # Connect using ODBC connection string
      # Supports DSN-based or DSN-less connections
      # e.g. "DSN=virt5;UID=rails;PWD=rails"
      #      "DRIVER={OpenLink Virtuoso};HOST=carlmbp;UID=rails;PWD=rails"
      def odbc_conn_str_connection(config)
        attrs = config[:conn_str].split(';').map { |option| option.split('=', 2) }.to_h
        odbc_module = attrs['ENCODING'] == 'utf8' ? ODBC_UTF8 : ODBC
        driver = odbc_module::Driver.new
        driver.name = 'odbc'
        driver.attrs = attrs

        connection = odbc_module::Database.new.drvconnect(driver)
        # encoding_bug indicates that the driver is using non ASCII and has the issue referenced here https://github.com/larskanis/ruby-odbc/issues/2
        [connection, config.merge(driver: driver, encoding: attrs['ENCODING'], encoding_bug: attrs['ENCODING'] == 'utf8')]
      end
    end
  end

  module ConnectionAdapters
    class ODBCAdapter < AbstractAdapter
      include ::ODBCAdapter::DatabaseLimits
      include ::ODBCAdapter::DatabaseStatements
      include ::ODBCAdapter::Quoting
      include ::ODBCAdapter::SchemaStatements

      ADAPTER_NAME = 'ODBC'.freeze
      BOOLEAN_TYPE = 'BOOLEAN'.freeze
      VARIANT_TYPE = 'VARIANT'.freeze
      DATE_TYPE = 'DATE'.freeze
      JSON_TYPE = 'JSON'.freeze

      ERR_DUPLICATE_KEY_VALUE                     = 23_505
      ERR_QUERY_TIMED_OUT                         = 57_014
      ERR_QUERY_TIMED_OUT_MESSAGE                 = /Query has timed out/
      ERR_CONNECTION_FAILED_REGEX                 = '^08[0S]0[12347]'.freeze
      ERR_CONNECTION_FAILED_MESSAGE               = /Client connection failed/

      # The object that stores the information that is fetched from the DBMS
      # when a connection is first established.
      attr_reader :database_metadata

      def initialize(connection, logger, config, database_metadata)
        configure_time_options(connection)
        super(connection, logger, config)
        @database_metadata = database_metadata
      end

      # Returns the human-readable name of the adapter.
      def adapter_name
        ADAPTER_NAME
      end

      # Does this adapter support migrations? Backend specific, as the abstract
      # adapter always returns +false+.
      def supports_migrations?
        true
      end

      # CONNECTION MANAGEMENT ====================================

      # Checks whether the connection to the database is still active. This
      # includes checking whether the database is actually capable of
      # responding, i.e. whether the connection isn't stale.
      def active?
        @connection.connected?
      end

      # Disconnects from the database if already connected, and establishes a
      # new connection with the database.
      def reconnect!
        disconnect!
        odbc_module = @config[:encoding] == 'utf8' ? ODBC_UTF8 : ODBC
        @connection =
          if @config.key?(:dsn)
            odbc_module.connect(@config[:dsn], @config[:username], @config[:password])
          else
            odbc_module::Database.new.drvconnect(@config[:driver])
          end
        configure_time_options(@connection)
        super
      end
      alias reset! reconnect!

      # Disconnects from the database if already connected. Otherwise, this
      # method does nothing.
      def disconnect!
        @connection.disconnect if @connection.connected?
      end

      # Build a new column object from the given options. Effectively the same
      # as super except that it also passes in the native type.
      # rubocop:disable Metrics/ParameterLists
      def new_column(name, default, sql_type_metadata, null, native_type = nil)
        ::ODBCAdapter::Column.new(name, default, sql_type_metadata, null, native_type)
      end

      protected

      #Snowflake ODBC Adapter specific
      def initialize_type_map(map)
        map.register_type :boolean,               Type::Boolean.new
        map.register_type :date,                  Type::Date.new
        map.register_type :string,                Type::String.new
        map.register_type :datetime,              Type::DateTime.new
        map.register_type :time,                  Type::Time.new
        map.register_type :binary,                Type::Binary.new
        map.register_type :float,                 Type::Float.new
        map.register_type :integer,               Type::Integer.new
        map.register_type(:decimal) do |_sql_type, column_data|
          Type::Decimal.new(precision: column_data.precision, scale: column_data.scale)
        end
        map.register_type :object,                ::ODBCAdapter::Type::SnowflakeObject.new
        map.register_type :array,                 ::ODBCAdapter::Type::ArrayOfValues.new
        map.register_type :variant,               ::ODBCAdapter::Type::Variant.new
      end

      # Translate an exception from the native DBMS to something usable by
      # ActiveRecord.
      def translate_exception(exception, message:, sql:, binds:)
        error_number = exception.message[/^\d+/].to_i

        if error_number == ERR_DUPLICATE_KEY_VALUE
          ActiveRecord::RecordNotUnique.new(message, exception)
        elsif error_number == ERR_QUERY_TIMED_OUT || exception.message =~ ERR_QUERY_TIMED_OUT_MESSAGE
          ::ODBCAdapter::QueryTimeoutError.new(message, exception)
        elsif exception.message.match(ERR_CONNECTION_FAILED_REGEX) || exception.message =~ ERR_CONNECTION_FAILED_MESSAGE
          begin
            reconnect!
            ::ODBCAdapter::ConnectionFailedError.new(message, exception)
          rescue => e
            puts "unable to reconnect #{e}"
          end
        else
          super
        end
      end

      private

      # Can't use the built-in ActiveRecord map#alias_type because it doesn't
      # work with non-string keys, and in our case the keys are (almost) all
      # numeric
      def alias_type(map, new_type, old_type)
        map.register_type(new_type) do |_, *args|
          map.lookup(old_type, *args)
        end
      end

      # Ensure ODBC is mapping time-based fields to native ruby objects
      def configure_time_options(connection)
        connection.use_time = true
      end
    end
  end
end
