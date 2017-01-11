module ODBCAdapter
  class DBMS
    module MySQLExt
      class BindSubstitution < Arel::Visitors::MySQL
        include Arel::Visitors::BindVisitor
      end
    end
  end
end
