module ODBCAdapter
  module DatabaseLimits
    # Returns the maximum length of a table name.
    def table_alias_length
      max_identifier_length = dbms.field_for(ODBC::SQL_MAX_IDENTIFIER_LEN)
      max_table_name_length = dbms.field_for(ODBC::SQL_MAX_TABLE_NAME_LEN)
      [max_identifier_length, max_table_name_length].max
    end
  end
end
