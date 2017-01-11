module ODBCAdapter
  class DBMS
    module PostgreSQLExt
      class BindSubstitution < Arel::Visitors::PostgreSQL
        include Arel::Visitors::BindVisitor
      end
    end
  end
end
