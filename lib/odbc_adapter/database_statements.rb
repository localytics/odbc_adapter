module ODBCAdapter
  module DatabaseStatements
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
        columns = stmt.columns.keys
        values  = stmt.to_a

        stmt.drop
        result = ActiveRecord::Result.new(columns, values)
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
  end
end
