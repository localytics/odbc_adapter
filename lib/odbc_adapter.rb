# Requiring with this pattern to mirror ActiveRecord
require 'active_record/connection_adapters/odbc_adapter'

module ODBCAdapter
  class << self
    def dbms_registry
      @dbms_registry ||= {
        /my.*sql/i => :MySQL,
        /postgres/i => :PostgreSQL
      }
    end

    def register(pattern, superclass = Object, &block)
      dbms_registry[pattern] = Class.new(superclass, &block)
    end
  end
end
