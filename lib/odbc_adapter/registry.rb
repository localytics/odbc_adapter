module ODBCAdapter
  class Registry
    attr_reader :dbs

    def initialize
      @dbs = {
        /my.*sql/i  => :MySQL,
        /postgres/i => :PostgreSQL
      }
    end

    def adapter_for(reported_name)
      reported_name = reported_name.downcase.gsub(/\s/, '')
      found =
        dbs.detect do |pattern, adapter|
          adapter if reported_name =~ pattern
        end

      normalize_adapter(found && found.last || :Null)
    end

    def register(pattern, superclass = Object, &block)
      dbs[pattern] = Class.new(superclass, &block)
    end

    private

    def normalize_adapter(adapter)
      return adapter unless adapter.is_a?(Symbol)
      require "odbc_adapter/adapters/#{adapter.downcase}_odbc_adapter"
      Adapters.const_get(:"#{adapter}ODBCAdapter")
    end
  end

  class << self
    def adapter_for(reported_name)
      registry.adapter_for(reported_name)
    end

    def register(pattern, superclass = Object, &block)
      registry.register(pattern, superclass, &block)
    end

    private

    def registry
      @registry ||= Registry.new
    end
  end
end
