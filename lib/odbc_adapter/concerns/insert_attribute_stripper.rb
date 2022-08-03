module ODBCAdapter
  module InsertAttributeStripper
    extend ActiveSupport::Concern
    include EasyIdentified

    included do
      alias_method :pre_insert_attribute_stripper_save, :save
      alias_method :pre_insert_attribute_stripper_save!, :save!

      def save(**options, &block)
        save_internal(method(:pre_insert_attribute_stripper_save), **options, &block)
      end

      def save!(**options, &block)
        save_internal(method(:pre_insert_attribute_stripper_save!), **options, &block)
      end

      private

      UNSAFE_INSERT_TYPES ||= %i(variant object array)

      def save_internal(base_function, **options, &block)
        self.class.transaction do
          if new_record?
            stripped_attributes = {}
            self.class.columns.each do |column|
              if UNSAFE_INSERT_TYPES.include?(column.type) && attributes[column.name] != nil
                stripped_attributes[column.name] = attributes[column.name]
                self[column.name] = nil
              end
            end
            if stripped_attributes.any? then generate_id end
          else
            stripped_attributes = {}
          end
          first_call_result = base_function.call(**options, &block)
          if stripped_attributes.any?
            restore_stripped_attributes(stripped_attributes)
            return base_function.call(**options, &block)
          else
            return first_call_result
          end
        end
      end

      def restore_stripped_attributes(stripped_attributes)
        stripped_attributes.each do |key, value|
          self[key] = value
        end
      end
    end
  end
end
