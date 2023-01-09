module ODBCAdapter
  module InsertAttributeStripper
    extend ActiveSupport::Concern

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
        # Unless the validations are turned off or the hash is valid just run the save. This will trigger validation
        # errors normally for an invalid record. We then disable validations during the initial save, because we'll
        # often be saving a technically invalid record as we've stripped off required elements.
        unless options[:validate] == false || valid?
          return base_function.call(**options, &block)
        end
        self.class.transaction do
          if new_record?
            stripped_attributes = {}
            self.class.columns.each do |column|
              if UNSAFE_INSERT_TYPES.include?(column.type) && attributes[column.name] != nil
                stripped_attributes[column.name] = attributes[column.name]
                self[column.name] = nil
              end
            end
          else
            stripped_attributes = {}
          end
          temp_options = options.merge(validate: false)
          first_call_result = base_function.call(**temp_options, &block)
          return false if first_call_result == false
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
