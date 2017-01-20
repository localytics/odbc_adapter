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

    def current_database
      dbms.field_for(ODBC::SQL_DATABASE_NAME).strip
    end

    # Returns an array of table names, for database tables visible on the
    # current connection.
    def tables(_name = nil)
      stmt   = @connection.tables
      result = stmt.fetch_all || []
      stmt.drop

      result.each_with_object([]) do |row, table_names|
        schema_name, table_name, table_type = row[1..3]
        next if respond_to?(:table_filtered?) && table_filtered?(schema_name, table_type)
        table_names << format_case(table_name)
      end
    end

    # Returns an array of Column objects for the table specified by +table_name+.
    def columns(table_name, name = nil)
      stmt   = @connection.columns(native_case(table_name.to_s))
      result = stmt.fetch_all || []
      stmt.drop

      result.each_with_object([]) do |col, cols|
        col_name        = col[3]  # SQLColumns: COLUMN_NAME
        col_default     = col[12] # SQLColumns: COLUMN_DEF
        col_sql_type    = col[4]  # SQLColumns: DATA_TYPE
        col_native_type = col[5]  # SQLColumns: TYPE_NAME
        col_limit       = col[6]  # SQLColumns: COLUMN_SIZE
        col_scale       = col[8]  # SQLColumns: DECIMAL_DIGITS

        # SQLColumns: IS_NULLABLE, SQLColumns: NULLABLE
        col_nullable = nullability(col_name, col[17], col[10])

        cast_type = lookup_cast_type(col_sql_type)
        cols << new_column(format_case(col_name), col_default, cast_type, col_sql_type, col_nullable, col_scale, col_limit)
      end
    end

    # Returns an array of indexes for the given table.
    def indexes(table_name, name = nil)
      stmt   = @connection.indexes(native_case(table_name.to_s))
      result = stmt.fetch_all || []
      stmt.drop unless stmt.nil?

      index_cols = []
      index_name = nil
      unique     = nil

      result.each_with_object([]).with_index do |(row, indices), row_idx|
        # Skip table statistics
        next if row[6] == 0 # SQLStatistics: TYPE

        if row[7] == 1 # SQLStatistics: ORDINAL_POSITION
          # Start of column descriptor block for next index
          index_cols = []
          unique     = row[3].zero? # SQLStatistics: NON_UNIQUE
          index_name = String.new(row[5]) # SQLStatistics: INDEX_NAME
        end

        index_cols << format_case(row[8]) # SQLStatistics: COLUMN_NAME
        next_row = result[row_idx + 1]

        if (row_idx == result.length - 1) || (next_row[6] == 0 || next_row[7] == 1)
          indices << IndexDefinition.new(table_name, format_case(index_name), unique, index_cols)
        end
      end
    end

    # Returns just a table's primary key
    def primary_key(table_name)
      stmt   = @connection.primary_keys(native_case(table_name.to_s))
      result = stmt.fetch_all || []
      stmt.drop unless stmt.nil?
      result[0] && result[0][3]
    end
  end
end
