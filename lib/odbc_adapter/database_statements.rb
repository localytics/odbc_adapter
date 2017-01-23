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
    # TODO: Currently ignoring binds until we can get prepared statements working.
    def execute(sql, name = nil, binds = [])
      log(sql, name) do
        @connection.do(sql)
      end
    end

    # Executes +sql+ statement in the context of this connection using
    # +binds+ as the bind substitutes. +name+ is logged along with
    # the executed +sql+ statement.
    def exec_query(sql, name = 'SQL', binds = [], prepare: false)
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

        values = dbms_type_cast(columns.values, values)
        column_names = columns.keys.map { |key| format_case(key) }
        result = ActiveRecord::Result.new(column_names, values)
      end
    end

    # Executes delete +sql+ statement in the context of this connection using
    # +binds+ as the bind substitutes. +name+ is logged along with
    # the executed +sql+ statement.
    def exec_delete(sql, name, binds)
      execute(sql, name, binds)
    end
    alias :exec_update :exec_delete

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

    def dbms_type_cast(columns, values)
      values
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
