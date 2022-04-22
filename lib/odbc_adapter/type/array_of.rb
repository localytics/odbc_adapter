module ODBCAdapter
  module Type
    def Type.array_of(type)
      newArrayClass = Class.new(ActiveRecord::Type::Value)

      newArrayClass.define_method :cast_value do |value|
        return value unless value.is_a? String
        base_array = ActiveSupport::JSON.decode(value) rescue nil
        base_array.map { |element| type.cast(element) }
      end

      newArrayClass.define_method :serialize do |value|
        value.to_a.map { |element| type.serialize(element)} unless value.nil?
      end

      newArrayClass.define_method :changed_in_place? do |raw_old_value, new_value|
        deserialize(raw_old_value) != new_value
      end

      newArrayClass
    end
  end
end
