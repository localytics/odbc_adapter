module ODBCAdapter
  module InsertAttributeStripper
    extend ActiveSupport::Concern
    include EasyIdentified

    included do
      alias_method :pre_insert_attribute_stripper_save, :save
      alias_method :pre_insert_attribute_stripper_save!, :save!

      def save(**options, &block)
        ActiveRecord::Base.transaction do
          if new_record?
            striped_attributes = strip_unsafe_to_insert
            if striped_attributes.any? then generate_id end
          end
          pre_insert_attribute_stripper_save(**options, &block)
          if striped_attributes.any?
            restore_stripped_attributes(striped_attributes)
            pre_insert_attribute_stripper_save(**options, &block)
          end
        end
      end

      def save!(**options, &block)
        ActiveRecord::Base.transaction do
          if new_record?
            striped_attributes = strip_unsafe_to_insert
            if striped_attributes.any? then generate_id end
          end
          pre_insert_attribute_stripper_save!(**options, &block)
          if striped_attributes.any?
            restore_stripped_attributes(striped_attributes)
            pre_insert_attribute_stripper_save!(**options, &block)
          end
        end
      end

      private

      UNSAFE_INSERT_TYPES ||= %i(variant object array)

      def strip_unsafe_to_insert
        striped_attributes = {}
        self.class.columns.each do |column|
          if UNSAFE_INSERT_TYPES.include?(column.type) && attributes[column.name] != nil
            striped_attributes[column.name] = attributes[column.name]
            self[column.name] = nil
          end
        end
        striped_attributes
      end

      def restore_stripped_attributes(stripped_attributes)
        stripped_attributes.each do |key, value|
          self[key] = value
        end
      end
    end
  end
end
