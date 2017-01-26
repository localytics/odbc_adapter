module ODBCAdapter
  class Column < ActiveRecord::ConnectionAdapters::Column
    attr_reader :native_type

    def initialize(name, default, cast_type, sql_type = nil, null = nil, native_type = nil, scale = nil, limit = nil)
      @name        = name
      @default     = default
      @cast_type   = cast_type
      @sql_type    = sql_type
      @null        = null
      @native_type = native_type

      if [ODBC::SQL_DECIMAL, ODBC::SQL_NUMERIC].include?(sql_type)
        set_numeric_params(scale, limit)
      end
    end

    private

    def set_numeric_params(scale, limit)
      @cast_type.instance_variable_set(:@scale, scale || 0)
      @cast_type.instance_variable_set(:@precision, limit)
    end
  end
end
