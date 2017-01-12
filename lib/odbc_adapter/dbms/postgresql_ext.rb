module ODBCAdapter
  class DBMS
    # Overrides specific to PostgreSQL. Mostly taken from
    # ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
    module PostgreSQLExt
      class BindSubstitution < Arel::Visitors::PostgreSQL
        include Arel::Visitors::BindVisitor
      end

      # Returns the sequence name for a table's primary key or some other specified key.
      def default_sequence_name(table, column = nil)
        serial_sequence(table_name, column || 'id').split('.').last
      rescue ActiveRecord::StatementInvalid
        "#{table_name}_#{column || 'id'}_seq"
      end

      # Executes an INSERT query and returns the new record's ID
      def insert_sql(sql, name = nil, pk = nil, id_value = nil, sequence_name = nil)
        unless pk
          table_ref = extract_table_ref_from_insert_sql(sql)
          pk = primary_key(table_ref) if table_ref
        end

        if pk
          select_value("#{sql} RETURNING #{quote_column_name(pk)}")
        else
          super
        end
      end

      def sql_for_insert(sql, pk, id_value, sequence_name, binds)
        unless pk
          table_ref = extract_table_ref_from_insert_sql(sql)
          pk = primary_key(table_ref) if table_ref
        end

        sql = "#{sql} RETURNING #{quote_column_name(pk)}" if pk
        [sql, binds]
      end

      def type_cast(value, column)
        return super unless column

        case value
        when String
          return super unless 'bytea' == column.sql_type
          { value: value, format: 1 }
        else
          super
        end
      end

      # Quotes a string, escaping any ' (single quote) and \ (backslash)
      # characters.
      def quote_string(string)
        string.gsub(/\\/, '\&\&').gsub(/'/, "''")
      end

      def quoted_true
        "'t'"
      end

      def quoted_false
        "'f'"
      end

      private

      def serial_sequence(table, column)
        result = exec_query(<<-eosql, 'SCHEMA')
          SELECT pg_get_serial_sequence('#{table}', '#{column}')
        eosql
        result.rows.first.first
      end
    end
  end
end
