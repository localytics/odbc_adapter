module ODBCAdapter
  module AutoIdentified
    extend ActiveSupport::Concern
    include EasyIdentified

    included do
      alias_method :pre_auto_identified_save, :save
      alias_method :pre_auto_identified_save!, :save!

      def save(**options, &block)
        generate_id
        pre_auto_identified_save(**options, &block)
      end

      def save!(**options, &block)
        generate_id
        pre_auto_identified_save!(**options, &block)
      end
    end
  end
end
