module ODBCAdapter
  module SchemaStatements
    # Returns a Hash of mappings from the abstract data types to the native
    # database types. See TableDefinition#column for details on the recognized
    # abstract data types.
    def native_database_types
      @native_database_types ||= ColumnMetadata.new(self).native_database_types
    end

    # Ensure it's shorter than the maximum identifier length for the current dbms
    def index_name(table_name, options)
      maximum = dbms.field_for(ODBC::SQL_MAX_IDENTIFIER_LEN) || 255
      super(table_name, options)[0...maximum]
    end
  end
end
