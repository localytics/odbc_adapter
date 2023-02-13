module ODBCAdapter
  module DatabaseStatements
    # ODBC constants missing from Christian Werner's Ruby ODBC driver
    SQL_NO_NULLS = 0
    SQL_NULLABLE = 1
    SQL_NULLABLE_UNKNOWN = 2

    # Executes the SQL statement in the context of this connection.
    # Returns the number of rows affected.
    def execute(sql, name = nil, binds = [])
      log(sql, name) do
        sql = bind_params(binds, sql) if prepared_statements
        @connection.do(sql)
      end
    end

    # Executes +sql+ statement in the context of this connection using
    # +binds+ as the bind substitutes. +name+ is logged along with
    # the executed +sql+ statement.
    def exec_query(sql, name = 'SQL', binds = [], prepare: false) # rubocop:disable Lint/UnusedMethodArgument
      log(sql, name) do
        sql = bind_params(binds, sql) if prepared_statements
        stmt =  @connection.run(sql)

        columns = stmt.columns
        values  = stmt.to_a
        stmt.drop

        values = dbms_type_cast(columns.values, values)
        column_names = columns.keys.map { |key| format_case(key) }
        ActiveRecord::Result.new(column_names, values)
      end
    end

    # Executes delete +sql+ statement in the context of this connection using
    # +binds+ as the bind substitutes. +name+ is logged along with
    # the executed +sql+ statement.
    def exec_delete(sql, name, binds)
      execute(sql, name, binds)
    end
    alias exec_update exec_delete

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
    def exec_rollback_db_transaction
      @connection.rollback
      @connection.autocommit = true
    end

    # Returns the default sequence name for a table.
    # Used for databases which don't support an autoincrementing column
    # type, but do support sequences.
    def default_sequence_name(table, _column)
      "#{table}_seq"
    end

    private

    # A custom hook to allow end users to overwrite the type casting before it
    # is returned to ActiveRecord. Useful before a full adapter has made its way
    # back into this repository.
    def dbms_type_cast(_columns, values)
      values
    end

    def bind_params(binds, sql)
      prepared_binds = *prepared_binds(binds)
      prepared_binds.each.with_index(1) do |val, ind|
        sql = sql.gsub("$#{ind}", "'#{val}'")
      end
      sql
    end

    # Assume received identifier is in DBMS's data dictionary case.
    def format_case(identifier)
      if database_metadata.upcase_identifiers?
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
      if database_metadata.upcase_identifiers?
        identifier =~ /[A-Z]/ ? identifier : identifier.upcase
      else
        identifier
      end
    end

    # Assume column is nullable if nullable == SQL_NULLABLE_UNKNOWN
    def nullability(col_name, is_nullable, nullable)
      not_nullable = (!is_nullable || !nullable.to_s.match('NO').nil?)
      result = !(not_nullable || nullable == SQL_NO_NULLS)

      # HACK!
      # MySQL native ODBC driver doesn't report nullability accurately.
      # So force nullability of 'id' columns
      col_name == 'id' ? false : result
    end

    # Adapt to Rails 5.2
    def prepare_statement_sub(sql)
      sql.gsub(/\$\d+/, '?')
    end

    def prepared_binds(binds)
      binds.map(&:value_for_database).map { |bind| _type_cast(bind) }
    end
  end
end
