require 'active_record/connection_adapters/abstract_adapter'

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

        ConnectionAdapters::ODBCAdapter.new(connection, logger, options.merge(
          convert_numeric_literals: config[:convert_numeric_literals] || false,
          emulate_booleans: config[:emulate_booleans] || false
        ))
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
      # - supports DSN-based or DSN-less connections
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
      attr_reader :convert_numeric_literals, :emulate_booleans

      def initialize(connection, logger, options)
        super(connection, logger)

        @connection               = connection
        @convert_numeric_literals = options[:conv_num_lits]
        @emulate_booleans         = options[:emulate_booleans]

        # # Caches SQLGetInfo output
        # @dsInfo = DSInfo.new(connection)
        # # Caches SQLGetTypeInfo output
        # @typeInfo = nil
        # # Caches mapping of Rails abstract data types to DBMS native types.
        # @abstract2NativeTypeMap = nil
        #
        # @visitor = BindSubstitution.new self
        #
        # # Set @dbmsName and @dbmsMajorVer from SQLGetInfo output.
        # # Each ODBCAdapter instance is associated with only one connection,
        # # so using ODBCAdapter instance variables for DBMS name and version
        # # is OK.
        #
        # @dbmsMajorVer = @dsInfo.info[ODBC::SQL_DBMS_VER].split('.')[0].to_i
        # @dbmsName = @dsInfo.info[ODBC::SQL_DBMS_NAME].downcase.gsub(/\s/,'')
        # # Different ODBC drivers might return different names for the same
        # # DBMS. So map similar names to the same symbol.
        # @dbmsName = dbmsNameToSym(@dbmsName, @dbmsMajorVer)
        #
        # # Now we know which DBMS we're connected to, extend this ODBCAdapter
        # # instance with the appropriate DBMS specific extensions
        # @odbcExtFile = "active_record/vendor/odbcext_#{@dbmsName}"
        #
        # begin
        #   require "#{@odbcExtFile}"
        #   self.extend ODBCExt
        # rescue MissingSourceFile
        #   puts "ODBCAdapter#initialize> Couldn't find extension #{@odbcExtFile}.rb"
        # end
      end
    end
  end
end
