module ODBCAdapter
  module Type
    class Variant < ActiveRecord::Type::Value

      def deserialize(value)
        # deserialize can contain the results of the previous serialize, rather than the database returned value
        if value.is_a? SnowflakeVariant then return value.internal_data end
        ActiveSupport::JSON.decode(value) rescue nil
      end

      def cast(value)
        value
      end

      def serialize(value)
        SnowflakeVariant.new(value) unless value.nil?
      end

      def changed_in_place?(raw_old_value, new_value)
        deserialize(raw_old_value) != new_value
      end

      def accessor
        ActiveRecord::Store::StringKeyedHashAccessor
      end
    end
  end
end
