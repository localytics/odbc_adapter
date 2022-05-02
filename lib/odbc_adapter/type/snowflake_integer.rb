
module ODBCAdapter
  module Type
    class SnowflakeInteger < ActiveRecord::Type::Integer
      # In order to allow for querying of IDs,
      def cast(value)
        if value == :auto_generate
          return value
        else
          super
        end
      end
    end
  end
end
