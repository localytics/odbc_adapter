module ODBCAdapter
  # Caches SQLGetInfo output
  class DBMS
    FIELDS = [
      ODBC::SQL_DBMS_NAME,
      ODBC::SQL_DBMS_VER,
      ODBC::SQL_IDENTIFIER_CASE,
      ODBC::SQL_QUOTED_IDENTIFIER_CASE,
      ODBC::SQL_IDENTIFIER_QUOTE_CHAR,
      ODBC::SQL_MAX_IDENTIFIER_LEN,
      ODBC::SQL_MAX_TABLE_NAME_LEN,
      ODBC::SQL_USER_NAME,
      ODBC::SQL_DATABASE_NAME
    ]

    attr_reader :connection, :fields

    def initialize(connection)
      @connection = connection
      @fields     = Hash[FIELDS.map { |field| [field, connection.get_info(field)] }]
    end

    def ext_module
      @ext_module ||=
        begin
          require "odbc_adapter/dbms/#{name.downcase}_ext"
          DBMS.const_get(:"#{name}Ext")
        end
    end

    def field_for(field)
      fields[field]
    end

    def visitor(adapter)
      ext_module::BindSubstitution.new(adapter)
    end

    private

    # Maps a DBMS name to a symbol
    # Different ODBC drivers might return different names for the same DBMS
    def name
      @name ||=
        begin
          reported = field_for(ODBC::SQL_DBMS_NAME).downcase.gsub(/\s/, '')
          case reported
          when /my.*sql/i               then :MySQL
          when /postgres/i, 'snowflake' then :PostgreSQL
          else
            raise ArgumentError, "ODBCAdapter: Unsupported database (#{reported})"
          end
        end
    end
  end
end
