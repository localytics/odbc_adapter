
module ODBCAdapter
  module EasyIdentified
    extend ActiveSupport::Concern

    included do
      alias_method :pre_easy_identified_save, :save
      alias_method :pre_easy_identified_save!, :save!

      def save(**options, &block)
        if self[:id] == :auto_generate then generate_id(true) end
        pre_easy_identified_save(**options, &block)
      end

      def save!(**options, &block)
        if self[:id] == :auto_generate then generate_id(true) end
        pre_easy_identified_save!(**options, &block)
      end

      def generate_id(force_new = false)
        if self[:id] == nil || force_new then self[:id] = retrieve_id end
      end

      private

      def retrieve_id
        sequence_name = self.class.table_name + "_ID_SEQ"
        self.class.connection.exec_query("Select #{sequence_name}.nextval as new_id")[0]["new_id"]
      end
    end
  end
end
