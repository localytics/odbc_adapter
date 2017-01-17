module ODBCAdapter
  module DatabaseStatements
    # ODBC constants missing from Christian Werner's Ruby ODBC driver
    SQL_NO_NULLS = 0
    SQL_NULLABLE = 1
    SQL_NULLABLE_UNKNOWN = 2

    # Returns an array of arrays containing the field values.
    # Order is the same as that returned by #columns.
    def select_rows(sql, name = nil)
      log(sql, name) do
        stmt   = @connection.run(sql)
        result = stmt.fetch_all
        stmt.drop
        result
      end
    end

    # Executes the SQL statement in the context of this connection.
    # Returns the number of rows affected.
    def execute(sql, name = nil)
      log(sql, name) do
        @connection.do(sql)
      end
    end

    # Executes +sql+ statement in the context of this connection using
    # +binds+ as the bind substitutes. +name+ is logged along with
    # the executed +sql+ statement.
    def exec_query(sql, name = 'SQL', binds = [])
      log(sql, name) do
        stmt    = @connection.run(sql)
        columns = stmt.columns
        values  = stmt.to_a
        stmt.drop

        casters = TypeCaster.build_from(columns.values)
        if casters.any?
          values.each do |row|
            casters.each { |caster| row[caster.idx] = caster.cast(row[caster.idx]) }
          end
        end

        result = ActiveRecord::Result.new(columns.keys, values)
      end
    end

    # Begins the transaction (and turns off auto-committing).
    def begin_db_transaction
      @connection.autocommit = false
    end

    # Commits the transaction (and turns on auto-committing).
    def commit_db_transaction
      @connection.commit
      @connection.autocommit = true
    end

    # Rolls back the transaction (and turns on auto-committing). Must be
    # done if the transaction block raises an exception or returns false.
    def rollback_db_transaction
      @connection.rollback
      @connection.autocommit = true
    end

    # Returns the default sequence name for a table.
    # Used for databases which don't support an autoincrementing column
    # type, but do support sequences.
    def default_sequence_name(table, _column)
      "#{table}_seq"
    end

    def recreate_database(name, options = {})
      drop_database(name)
      create_database(name, options)
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

    # The class of the column to instantiate
    def column_class
      ::ODBCAdapter::Column
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

        cols << column_class.new(format_case(col_name), col_default, col_sql_type, col_native_type, col_nullable, col_scale, native_database_types, col_limit)
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
      result && result[0][3]
    end

    ERR_DUPLICATE_KEY_VALUE = 23505

    def translate_exception(exception, message)
      case exception.message[/^\d+/].to_i
      when ERR_DUPLICATE_KEY_VALUE
        ActiveRecord::RecordNotUnique.new(message, exception)
      else
        super
      end
    end

    protected

    # Returns an array of record hashes with the column names as keys and
    # column values as values.
    def select(sql, name = nil, binds = [])
      exec_query(sql, name, binds).to_a
    end

    # Returns the last auto-generated ID from the affected table.
    def insert_sql(sql, name = nil, pk = nil, id_value = nil, sequence_name = nil)
      begin
        stmt  = log(sql, name) { @connection.run(sql) }
        table = extract_table_ref_from_insert_sql(sql)

        seq   = sequence_name || default_sequence_name(table, pk)
        res   = id_value || last_insert_id(table, seq, stmt)
      ensure
        stmt.drop unless stmt.nil?
      end
      res
    end

    private

    def extract_table_ref_from_insert_sql(sql)
      sql[/into\s+([^\(]*).*values\s*\(/i]
      $1.strip if $1
    end

    # Assume received identifier is in DBMS's data dictionary case.
    def format_case(identifier)
      case dbms.field_for(ODBC::SQL_IDENTIFIER_CASE)
      when ODBC::SQL_IC_UPPER
        identifier =~ /[a-z]/ ? identifier : identifier.downcase
      else
        identifier
      end
    end

    # In general, ActiveRecord uses lowercase attribute names. This may
    # conflict with the database's data dictionary case.
    #
    # The ODBCAdapter uses the following conventions for databases
    # which report SQL_IDENTIFIER_CASE = SQL_IC_UPPER:
    # * if a name is returned from the DBMS in all uppercase, convert it
    #   to lowercase before returning it to ActiveRecord.
    # * if a name is returned from the DBMS in lowercase or mixed case,
    #   assume the underlying schema object's name was quoted when
    #   the schema object was created. Leave the name untouched before
    #   returning it to ActiveRecord.
    # * before making an ODBC catalog call, if a supplied identifier is all
    #   lowercase, convert it to uppercase. Leave mixed case or all
    #   uppercase identifiers unchanged.
    # * columns created with quoted lowercase names are not supported.
    #
    # Converts an identifier to the case conventions used by the DBMS.
    # Assume received identifier is in ActiveRecord case.
    def native_case(identifier)
      case dbms.field_for(ODBC::SQL_IDENTIFIER_CASE)
      when ODBC::SQL_IC_UPPER
        identifier =~ /[A-Z]/ ? identifier : identifier.upcase
      else
        identifier
      end
    end

    # Assume column is nullable if nullable == SQL_NULLABLE_UNKNOWN
    def nullability(col_name, is_nullable, nullable)
      not_nullable = (!is_nullable || nullable.to_s.match('NO') != nil)
      result = !(not_nullable || nullable == SQL_NO_NULLS)

      # HACK!
      # MySQL native ODBC driver doesn't report nullability accurately.
      # So force nullability of 'id' columns
      col_name == 'id' ? false : result
    end
  end
end
