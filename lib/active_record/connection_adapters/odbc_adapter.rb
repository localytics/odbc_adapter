require 'active_record'
require 'arel/visitors/bind_visitor'
require 'odbc'

require 'odbc_adapter'
require 'odbc_adapter/database_limits'
require 'odbc_adapter/database_statements'
require 'odbc_adapter/quoting'
require 'odbc_adapter/schema_statements'

require 'odbc_adapter/column'
require 'odbc_adapter/column_metadata'
require 'odbc_adapter/database_metadata'
require 'odbc_adapter/registry'
require 'odbc_adapter/type_caster'
require 'odbc_adapter/version'

module ActiveRecord
  class Base
    class << self
      def odbc_connection(config) # :nodoc:
        config = config.symbolize_keys

        connection, options =
          if config.key?(:dsn)
            odbc_dsn_connection(config)
          elsif config.key?(:conn_str)
            odbc_conn_str_connection(config)
          else
            raise ArgumentError, "No data source name (:dsn) or connection string (:conn_str) specified."
          end

        database_metadata = ::ODBCAdapter::DatabaseMetadata.new(connection)
        database_metadata.adapter_class.new(connection, logger, database_metadata)
      end

      private

      def odbc_dsn_connection(config)
        username   = config[:username] ? config[:username].to_s : nil
        password   = config[:password] ? config[:password].to_s : nil
        connection = ODBC.connect(config[:dsn], username, password)
        options    = { dsn: config[:dsn], username: username, password: password }
        [connection, options]
      end

      # Connect using ODBC connection string
      # Supports DSN-based or DSN-less connections
      # e.g. "DSN=virt5;UID=rails;PWD=rails"
      #      "DRIVER={OpenLink Virtuoso};HOST=carlmbp;UID=rails;PWD=rails"
      def odbc_conn_str_connection(config)
        connstr_keyval_pairs = config[:conn_str].split(';')

        driver = ODBC::Driver.new
        driver.name = 'odbc'
        driver.attrs = {}

        connstr_keyval_pairs.each do |pair|
          keyval = pair.split('=')
          driver.attrs[keyval[0]] = keyval[1] if keyval.length == 2
        end

        connection = ODBC::Database.new.drvconnect(driver)
        options    = { conn_str: config[:conn_str], driver: driver }
        [connection, options]
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
      ERR_DUPLICATE_KEY_VALUE = 23505

      attr_reader :database_metadata

      def initialize(connection, logger, database_metadata)
        super(connection, logger)
        @connection        = connection
        @database_metadata = database_metadata
      end

      # Returns the human-readable name of the adapter. Use mixed case - one
      # can always use downcase if needed.
      def adapter_name
        ADAPTER_NAME
      end

      # Does this adapter support migrations? Backend specific, as the
      # abstract adapter always returns +false+.
      def supports_migrations?
        true
      end

      # CONNECTION MANAGEMENT ====================================

      # Checks whether the connection to the database is still active. This includes
      # checking whether the database is actually capable of responding, i.e. whether
      # the connection isn't stale.
      def active?
        @connection.connected?
      end

      # Disconnects from the database if already connected, and establishes a
      # new connection with the database.
      def reconnect!
        disconnect!
        @connection =
          if options.key?(:dsn)
            ODBC.connect(options[:dsn], options[:username], options[:password])
          else
            ODBC::Database.new.drvconnect(options[:driver])
          end
        super
      end
      alias :reset! :reconnect!

      # Disconnects from the database if already connected. Otherwise, this
      # method does nothing.
      def disconnect!
        @connection.disconnect if @connection.connected?
      end

      def new_column(name, default, sql_type_metadata, null, table_name, default_function = nil, collation = nil, native_type = nil)
        ::ODBCAdapter::Column.new(name, default, sql_type_metadata, null, table_name, default_function, collation, native_type)
      end

      protected

      def initialize_type_map(map)
        map.register_type 'boolean',              Type::Boolean.new
        map.register_type ODBC::SQL_CHAR,         Type::String.new
        map.register_type ODBC::SQL_LONGVARCHAR,  Type::Text.new
        map.register_type ODBC::SQL_TINYINT,      Type::Integer.new(limit: 4)
        map.register_type ODBC::SQL_SMALLINT,     Type::Integer.new(limit: 8)
        map.register_type ODBC::SQL_INTEGER,      Type::Integer.new(limit: 16)
        map.register_type ODBC::SQL_BIGINT,       Type::BigInteger.new(limit: 32)
        map.register_type ODBC::SQL_REAL,         Type::Float.new(limit: 24)
        map.register_type ODBC::SQL_FLOAT,        Type::Float.new
        map.register_type ODBC::SQL_DOUBLE,       Type::Float.new(limit: 53)
        map.register_type ODBC::SQL_DECIMAL,      Type::Float.new
        map.register_type ODBC::SQL_NUMERIC,      Type::Integer.new
        map.register_type ODBC::SQL_BINARY,       Type::Binary.new
        map.register_type ODBC::SQL_DATE,         Type::Date.new
        map.register_type ODBC::SQL_DATETIME,     Type::DateTime.new
        map.register_type ODBC::SQL_TIME,         Type::Time.new
        map.register_type ODBC::SQL_TIMESTAMP,    Type::DateTime.new
        map.register_type ODBC::SQL_GUID,         Type::String.new

        alias_type map, ODBC::SQL_BIT,            'boolean'
        alias_type map, ODBC::SQL_VARCHAR,        ODBC::SQL_CHAR
        alias_type map, ODBC::SQL_WCHAR,          ODBC::SQL_CHAR
        alias_type map, ODBC::SQL_WVARCHAR,       ODBC::SQL_CHAR
        alias_type map, ODBC::SQL_WLONGVARCHAR,   ODBC::SQL_LONGVARCHAR
        alias_type map, ODBC::SQL_VARBINARY,      ODBC::SQL_BINARY
        alias_type map, ODBC::SQL_LONGVARBINARY,  ODBC::SQL_BINARY
        alias_type map, ODBC::SQL_TYPE_DATE,      ODBC::SQL_DATE
        alias_type map, ODBC::SQL_TYPE_TIME,      ODBC::SQL_TIME
        alias_type map, ODBC::SQL_TYPE_TIMESTAMP, ODBC::SQL_TIMESTAMP
      end

      def translate_exception(exception, message)
        case exception.message[/^\d+/].to_i
        when ERR_DUPLICATE_KEY_VALUE
          ActiveRecord::RecordNotUnique.new(message, exception)
        else
          super
        end
      end

      private

      def alias_type(map, new_type, old_type)
        map.register_type(new_type) do |_, *args|
          map.lookup(old_type, *args)
        end
      end
    end
  end
end
