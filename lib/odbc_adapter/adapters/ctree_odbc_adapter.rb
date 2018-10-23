module ODBCAdapter
  module Adapters
    # A default adapter used for databases that are no explicitly listed in the
    # registry. This allows for minimal support for DBMSs for which we don't
    # have an explicit adapter.
    class CtreeODBCAdapter < ActiveRecord::ConnectionAdapters::ODBCAdapter
      class BindSubstitution < Arel::Visitors::ToSql
        def visit_Arel_Nodes_SelectStatement(o, collector)
          collector << "SELECT "
          collector = maybe_visit o.limit, collector
          collector = maybe_visit o.offset, collector
          collector = o.cores.inject(collector) { |c, x|
            visit_Arel_Nodes_SelectCore x, c
          }
          if o.orders.any?
            collector << " ORDER BY "
            collector = inject_join o.orders, collector, ", "
          end
          collector = maybe_visit o.lock, collector
        end
        def visit_Arel_Nodes_SelectCore(o, collector)
          collector = inject_join o.projections, collector, ", "
          if o.source && !o.source.empty?
            collector << " FROM "
            collector = visit o.source, collector
          end

          if o.wheres.any?
            collector << " WHERE "
            collector = inject_join o.wheres, collector, " AND "
          end

          if o.groups.any?
            collector << "GROUP BY "
            collector = inject_join o.groups, collector, ", "
          end

          if o.havings.any?
            collector << " HAVING "
            collector = inject_join o.havings, collector, " AND "
          end
          collector
        end

        def visit_Arel_Nodes_Offset(o, collector)
          collector << "SKIP "
          visit o.expr, collector
          collector << " "
        end

        def visit_Arel_Nodes_Limit(o, collector)
          collector << "TOP "
          visit o.expr, collector
          collector << " "
        end
      end

      def arel_visitor
        Arel::Visitors::Ctree.new(self)
      end
      # Using a BindVisitor so that the SQL string gets substituted before it is
      # sent to the DBMS (to attempt to get as much coverage as possible for
      # DBMSs we don't support).
      def arel_visitor
        BindSubstitution.new(self)
      end

      # Explicitly turning off prepared_statements in the null adapter because
      # there isn't really a standard on which substitution character to use.
      def prepared_statements
        false
      end

      # Turning off support for migrations because there is no information to
      # go off of for what syntax the DBMS will expect.
      def supports_migrations?
        false
      end
    end
  end
end
