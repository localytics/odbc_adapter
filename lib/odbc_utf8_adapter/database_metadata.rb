module ODBCUTF8Adapter
  # Caches SQLGetInfo output
  class DatabaseMetadata
    FIELDS = %i[
      SQL_DBMS_NAME
      SQL_DBMS_VER
      SQL_IDENTIFIER_CASE
      SQL_QUOTED_IDENTIFIER_CASE
      SQL_IDENTIFIER_QUOTE_CHAR
      SQL_MAX_IDENTIFIER_LEN
      SQL_MAX_TABLE_NAME_LEN
      SQL_USER_NAME
      SQL_DATABASE_NAME
    ]

    attr_reader :values

    def initialize(connection)
      @values = Hash[FIELDS.map { |field| [field, connection.get_info(ODBC_UTF8.const_get(field))] }]
    end

    def adapter_class
      ODBCUTF8Adapter.adapter_for(dbms_name)
    end

    def upcase_identifiers?
      @upcase_identifiers ||= (identifier_case == ODBC_UTF8::SQL_IC_UPPER)
    end

    # A little bit of metaprogramming magic here to create accessors for each of
    # the fields reported on by the DBMS.
    FIELDS.each do |field|
      define_method(field.to_s.downcase.gsub('sql_', '')) do
        value_for(field)
      end
    end

    private

    def value_for(field)
      values[field]
    end
  end
end
