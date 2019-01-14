module ODBCUTF8Adapter
  module DatabaseLimits
    # Returns the maximum length of a table name.
    def table_alias_length
      max_identifier_length = database_metadata.max_identifier_len
      max_table_name_length = database_metadata.max_table_name_len
      [max_identifier_length, max_table_name_length].max
    end
  end
end
