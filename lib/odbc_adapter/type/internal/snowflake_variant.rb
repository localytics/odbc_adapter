module ODBCAdapter
  module Type
    class SnowflakeVariant
      # Acts as a wrapper around other data types to make sure that they get typecasted into variants during quoting
      def initialize(internal_data)
        @internal_data = internal_data
      end

      def quote(adapter)
        adapter.quote(@internal_data) + "::VARIANT"
      end

      def internal_data
        @internal_data
      end
    end
  end
end
