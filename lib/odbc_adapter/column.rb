module ODBCAdapter
  class Column < ActiveRecord::ConnectionAdapters::Column
    def initialize(name, default, cast_type, sql_type, null, scale, limit)
      @name      = name
      @default   = default
      @cast_type = cast_type
      @sql_type  = sql_type
      @null      = null

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
