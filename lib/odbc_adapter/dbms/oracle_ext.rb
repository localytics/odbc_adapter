module ODBCAdapter
  class DBMS
    module OracleExt
      class BindSubstitution < Arel::Visitors::Oracle
        include Arel::Visitors::BindVisitor
      end

      # Ideally, we'd return an ODBC date or timestamp literal escape
      # sequence, but not all ODBC drivers support them.
      def quoted_date(value)
        if value.acts_like?(:time) # Time, DateTime
          "to_timestamp(\'#{value.strftime("%Y-%m-%d %H:%M:%S")}\', \'YYYY-MM-DD HH24:MI:SS\')"
        else # Date
          "to_timestamp(\'#{value.strftime("%Y-%m-%d")}\', \'YYYY-MM-DD\')"
        end
      end
    end
  end
end
