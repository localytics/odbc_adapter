module ODBCAdapter
  class DBMS
    # Overrides specific to PostgreSQL. Mostly taken from
    # ActiveRecord::ConnectionAdapters::MySQLAdapter
    module MySQLExt
      class BindSubstitution < Arel::Visitors::MySQL
        include Arel::Visitors::BindVisitor
      end

      def limited_update_conditions(where_sql, _quoted_table_name, _quoted_primary_key)
        where_sql
      end

      # Taken from ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter
      def join_to_update(update, select) #:nodoc:
        if select.limit || select.offset || select.orders.any?
          subsubselect = select.clone
          subsubselect.projections = [update.key]

          subselect = Arel::SelectManager.new(select.engine)
          subselect.project Arel.sql(update.key.name)
          subselect.from subsubselect.as('__active_record_temp')

          update.where update.key.in(subselect)
        else
          update.table select.source
          update.wheres = select.constraints
        end
      end

      protected

      def insert_sql(sql, name = nil, pk = nil, id_value = nil, sequence_name = nil)
        super
        id_value || last_inserted_id(nil)
      end

      def last_inserted_id(_result)
        @connection.last_id
      end
    end
  end
end
