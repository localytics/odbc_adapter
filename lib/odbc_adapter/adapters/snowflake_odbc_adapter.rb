module ODBCAdapter
  module Adapters
    # An adapter for use with Snowflake via ODBC
    class SnowflakeODBCAdapter < NullODBCAdapter
      include ::ODBCAdapter::Adapters::Snowflake::SchemaStatements

      def prepared_statements
        true
      end
    end
  end
end
