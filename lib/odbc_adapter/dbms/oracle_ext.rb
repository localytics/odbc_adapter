module ODBCAdapter
  class DBMS
    module OracleExt
      class BindSubstitution < Arel::Visitors::Oracle
        include Arel::Visitors::BindVisitor
      end
    end
  end
end
