# frozen_string_literal: true

module ODBCAdapter
  module Adapters
    # A default adapter used for databases that are no explicitly listed in the
    # registry. This allows for minimal support for DBMSs for which we don't
    # have an explicit adapter.
    class NullODBCAdapter < ActiveRecord::ConnectionAdapters::ODBCAdapter
      VARIANT_TYPE = 'VARIANT'
      DATE_TYPE = 'DATE'
      JSON_TYPE = 'JSON'
      # Using a BindVisitor so that the SQL string gets substituted before it is
      # sent to the DBMS (to attempt to get as much coverage as possible for
      # DBMSs we don't support).
      def arel_visitor
        Arel::Visitors::PostgreSQL.new(self)
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
