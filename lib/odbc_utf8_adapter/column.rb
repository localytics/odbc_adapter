module ODBCUTF8Adapter
  class Column < ActiveRecord::ConnectionAdapters::Column
    attr_reader :native_type

    def initialize(name, default, sql_type_metadata = nil, null = true, table_name = nil, native_type = nil, default_function = nil, collation = nil)
      super(name, default, sql_type_metadata, null, table_name, default_function, collation)
      @native_type = native_type
    end
  end
end
