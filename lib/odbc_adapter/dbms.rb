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

    attr_reader :fields

    def initialize(connection)
      @fields     = Hash[FIELDS.map { |field| [field, connection.get_info(field)] }]
    end

    def adapter_class
      require "odbc_adapter/adapters/#{name.downcase}_odbc_adapter"
      Adapters.const_get(:"#{name}ODBCAdapter")
    end

    def field_for(field)
      fields[field]
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
