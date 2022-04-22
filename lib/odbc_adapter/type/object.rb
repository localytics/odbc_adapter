module ODBCAdapter
  module Type
    class SnowflakeObject < ActiveRecord::Type::Value

      def cast_value(value)
        # deserialize can contain the results of the previous serialize, rather than the database returned value
        if value.is_a? Hash then return value end
        ActiveSupport::JSON.decode(value) rescue nil
      end

      def serialize(value)
        value.to_h unless value.nil?
      end

      def changed_in_place?(raw_old_value, new_value)
        deserialize(raw_old_value) != new_value
      end
    end
  end
end
