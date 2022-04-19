module ODBCAdapter
  module Type
    def Type.array(type)
      newArrayClass = Class.new(ActiveRecord::Type::Value)
      newArrayClass.define_method :cast_value do |value|
        base_array = ActiveSupport::JSON.decode(value) rescue nil
        base_array.map do |element|
          ret = type.cast(element)
          ret
        end
      end

      newArrayClass.define_method :serialize do |value|
        ActiveSupport::JSON.encode(value.map { |element| type.serialize(element)}) unless value.nil?
      end

      newArrayClass.define_method :changed_in_place? do |raw_old_value, new_value|
        deserialize(raw_old_value) != new_value
      end

      newArrayClass
    end
  end


end

ActiveRecord::Type.register(:array_of_big_integers, ODBCAdapter::Type.array(ActiveRecord::Type::BigInteger.new))
ActiveRecord::Type.register(:array_of_binaries, ODBCAdapter::Type.array(ActiveRecord::Type::Binary.new))
ActiveRecord::Type.register(:array_of_booleans, ODBCAdapter::Type.array(ActiveRecord::Type::Boolean.new))
ActiveRecord::Type.register(:array_of_dates, ODBCAdapter::Type.array(ActiveRecord::Type::Date.new))
ActiveRecord::Type.register(:array_of_date_times, ODBCAdapter::Type.array(ActiveRecord::Type::DateTime.new))
ActiveRecord::Type.register(:array_of_decimals, ODBCAdapter::Type.array(ActiveRecord::Type::Decimal.new))
ActiveRecord::Type.register(:array_of_floats, ODBCAdapter::Type.array(ActiveRecord::Type::Float.new))
ActiveRecord::Type.register(:array_of_immutable_strings, ODBCAdapter::Type.array(ActiveRecord::Type::ImmutableString.new))
ActiveRecord::Type.register(:array_of_integers, ODBCAdapter::Type.array(ActiveRecord::Type::Integer.new))
ActiveRecord::Type.register(:array_of_strings, ODBCAdapter::Type.array(ActiveRecord::Type::String.new))
ActiveRecord::Type.register(:array_of_times, ODBCAdapter::Type.array(ActiveRecord::Type::Time.new))
ActiveRecord::Type.register(:array_of_values, ODBCAdapter::Type.array(ActiveRecord::Type::Value.new))
