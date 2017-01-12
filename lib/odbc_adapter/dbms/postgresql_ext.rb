module ODBCAdapter
  class DBMS
    module PostgreSQLExt
      class BindSubstitution < Arel::Visitors::PostgreSQL
        include Arel::Visitors::BindVisitor
      end

      # Returns the default sequence name for a table.
      # Used for databases which don't support an autoincrementing column
      # type, but do support sequences.
      def default_sequence_name(table, column = nil)
        serial_sequence(table_name, column || 'id').split('.').last
      rescue ActiveRecord::StatementInvalid
        "#{table_name}_#{column || 'id'}_seq"
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
