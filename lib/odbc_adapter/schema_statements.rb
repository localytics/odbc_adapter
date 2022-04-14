module ODBCAdapter
  module SchemaStatements
    # Returns a Hash of mappings from the abstract data types to the native
    # database types. See TableDefinition#column for details on the recognized
    # abstract data types.
    def native_database_types
      @native_database_types ||= ColumnMetadata.new(self).native_database_types
    end

    # Returns an array of table names, for database tables visible on the
    # current connection.
    def tables(_name = nil)
      stmt   = @connection.tables
      result = stmt.fetch_all || []
      stmt.drop

      db_regex = name_regex(current_database)
      schema_regex = name_regex(current_schema)
      result.each_with_object([]) do |row, table_names|
        next unless row[0] =~ db_regex && row[1] =~ schema_regex
        schema_name, table_name, table_type = row[1..3]
        next if respond_to?(:table_filtered?) && table_filtered?(schema_name, table_type)
        table_names << format_case(table_name)
      end
    end

    # Returns an array of view names defined in the database.
    def views
      []
    end

    # Returns an array of indexes for the given table.
    def indexes(table_name, _name = nil)
      stmt   = @connection.indexes(native_case(table_name.to_s))
      result = stmt.fetch_all || []
      stmt.drop unless stmt.nil?

      index_cols = []
      index_name = nil
      unique     = nil

      db_regex = name_regex(current_database)
      schema_regex = name_regex(current_schema)
      result.each_with_object([]).with_index do |(row, indices), row_idx|
        next unless row[0] =~ db_regex && row[1] =~ schema_regex
        # Skip table statistics
        next if row[6].zero? # SQLStatistics: TYPE

        if row[7] == 1 # SQLStatistics: ORDINAL_POSITION
          # Start of column descriptor block for next index
          index_cols = []
          unique     = row[3].zero? # SQLStatistics: NON_UNIQUE
          index_name = String.new(row[5]) # SQLStatistics: INDEX_NAME
        end

        index_cols << format_case(row[8]) # SQLStatistics: COLUMN_NAME
        next_row = result[row_idx + 1]

        if (row_idx == result.length - 1) || (next_row[6].zero? || next_row[7] == 1)
          indices << ActiveRecord::ConnectionAdapters::IndexDefinition.new(table_name, format_case(index_name), unique, index_cols)
        end
      end
    end

    # Returns an array of Column objects for the table specified by
    # +table_name+.
    def columns(table_name, _name = nil)
      stmt   = @connection.columns(native_case(table_name.to_s))
      result = stmt.fetch_all || []
      stmt.drop

      db_regex = name_regex(current_database)
      schema_regex = name_regex(current_schema)
      result.each_with_object([]) do |col, cols|
        next unless col[0] =~ db_regex && col[1] =~ schema_regex
        col_name        = col[3]  # SQLColumns: COLUMN_NAME
        col_default     = col[12] # SQLColumns: COLUMN_DEF
        col_sql_type    = col[4]  # SQLColumns: DATA_TYPE
        col_native_type = col[5]  # SQLColumns: TYPE_NAME
        col_limit       = col[6]  # SQLColumns: COLUMN_SIZE
        col_scale       = col[8]  # SQLColumns: DECIMAL_DIGITS

        # SQLColumns: IS_NULLABLE, SQLColumns: NULLABLE
        col_nullable = nullability(col_name, col[17], col[10])

        # This section has been customized for Snowflake and will not work in general.
        args = { sql_type: col_native_type, type: col_native_type, limit: col_limit }
        args[:type] = :boolean if col_native_type == "BOOLEAN"  # self.class::BOOLEAN_TYPE
        args[:type] = :json if col_native_type == "VARIANT" || col_native_type == "JSON"
        args[:type] = :date if col_native_type == "DATE"
        args[:type] = :string if col_native_type == "VARCHAR"
        args[:type] = :datetime if col_native_type == "TIMESTAMP"
        args[:type] = :time if col_native_type == "TIME"
        args[:type] = :binary if col_native_type == "BINARY"
        args[:type] = :float if col_native_type == "DOUBLE"

        if [ODBC::SQL_DECIMAL, ODBC::SQL_NUMERIC].include?(col_sql_type)
          args[:type] = col_scale == 0 ? :integer : :decimal
          args[:scale]     = col_scale || 0
          args[:precision] = col_limit
        end
        sql_type_metadata = ActiveRecord::ConnectionAdapters::SqlTypeMetadata.new(**args)

        # The @connection.columns function returns empty strings for column defaults.
        # Even when the column has a default value. This is a call to the ODBC layer
        # with only enough Ruby to make the call happen. Replacing the empty string
        # with nil permits Rails to set the current datetime for created_at and
        # updated_at on model creates and updates.
        col_default = nil if col_default == ""

        cols << new_column(format_case(col_name), col_default, sql_type_metadata, col_nullable, col_native_type)
      end
    end

    # Returns just a table's primary key
    def primary_key(table_name)
      stmt   = @connection.primary_keys(native_case(table_name.to_s))
      result = stmt.fetch_all || []
      stmt.drop unless stmt.nil?

      db_regex = name_regex(current_database)
      schema_regex = name_regex(current_schema)
      result.reduce(nil) { |pkey, key| (key[0] =~ db_regex && key[1] =~ schema_regex) ? format_case(key[3]) : pkey }
    end

    def foreign_keys(table_name)
      stmt   = @connection.foreign_keys(native_case(table_name.to_s))
      result = stmt.fetch_all || []
      stmt.drop unless stmt.nil?

      db_regex = name_regex(current_database)
      schema_regex = name_regex(current_schema)
      result.map do |key|
        next unless key[0] =~ db_regex && key[1] =~ schema_regex
        fk_from_table      = key[2]  # PKTABLE_NAME
        fk_to_table        = key[6]  # FKTABLE_NAME

        ActiveRecord::ConnectionAdapters::ForeignKeyDefinition.new(
          fk_from_table,
          fk_to_table,
          name:        key[11], # FK_NAME
          column:      key[3],  # PKCOLUMN_NAME
          primary_key: key[7],  # FKCOLUMN_NAME
          on_delete:   key[10], # DELETE_RULE
          on_update:   key[9]   # UPDATE_RULE
        )
      end
    end

    # Ensure it's shorter than the maximum identifier length for the current
    # dbms
    def index_name(table_name, options)
      maximum = database_metadata.max_identifier_len || 255
      super(table_name, options)[0...maximum]
    end

    def current_database
      database_metadata.database_name.strip
    end

    def current_schema
      @config[:driver].attrs['schema']
    end

    def name_regex(name)
      if name =~ /^".*"$/
        /^#{name.delete_prefix('"').delete_suffix('"')}$/
      else
        /^#{name}$/i
      end
    end
  end
end
