module ODBCAdapter
  class Column < ActiveRecord::ConnectionAdapters::Column
    def initialize(name, default, sql_type, native_type, null = true, scale = nil, native_types = nil, limit = nil)
      @name        = name
      @default     = default
      @sql_type    = native_type.to_s
      @native_type = native_type.to_s
      @null        = null
      @precision   = extract_precision(sql_type, limit)
      @scale       = extract_scale(sql_type, scale)
      @type        = genericize(sql_type, @scale, native_types)
      @primary     = nil
    end

    private

    # Maps an ODBC SQL type to an ActiveRecord abstract data type
    #
    # c.f. Mappings in ConnectionAdapters::Column#simplified_type based on
    # native column type declaration
    #
    # See also:
    # Column#klass (schema_definitions.rb) for the Ruby class corresponding
    # to each abstract data type.
    def genericize(sql_type, scale, native_types)
      case sql_type
      when ODBC::SQL_BIT                                 then :boolean
      when ODBC::SQL_CHAR, ODBC::SQL_VARCHAR             then :string
      when ODBC::SQL_LONGVARCHAR                         then :text
      when ODBC::SQL_WCHAR, ODBC::SQL_WVARCHAR           then :string
      when ODBC::SQL_WLONGVARCHAR                        then :text
      when ODBC::SQL_TINYINT, ODBC::SQL_SMALLINT, ODBC::SQL_INTEGER, ODBC::SQL_BIGINT then :integer
      when ODBC::SQL_REAL, ODBC::SQL_FLOAT, ODBC::SQL_DOUBLE then :float
      # If SQLGetTypeInfo output of ODBC driver doesn't include a mapping
      # to a native type from SQL_DECIMAL/SQL_NUMERIC, map to :float
      when ODBC::SQL_DECIMAL, ODBC::SQL_NUMERIC          then numeric_type(scale, native_types)
      when ODBC::SQL_BINARY, ODBC::SQL_VARBINARY, ODBC::SQL_LONGVARBINARY then :binary
      # SQL_DATETIME is an alias for SQL_DATE in ODBC's sql.h & sqlext.h
      when ODBC::SQL_DATE, ODBC::SQL_TYPE_DATE, ODBC::SQL_DATETIME then :date
      when ODBC::SQL_TIME, ODBC::SQL_TYPE_TIME           then :time
      when ODBC::SQL_TIMESTAMP, ODBC::SQL_TYPE_TIMESTAMP then :timestamp
      when ODBC::SQL_GUID                                then :string
      else
        # when SQL_UNKNOWN_TYPE
        # (ruby-odbc driver doesn't support following ODBC SQL types:
        #  SQL_WCHAR, SQL_WVARCHAR, SQL_WLONGVARCHAR, SQL_INTERVAL_xxx)
        raise ArgumentError, "Unsupported ODBC SQL type [#{odbcSqlType}]"
      end
    end

    # Ignore the ODBC precision of SQL types which don't take
    # an explicit precision when defining a column
    def extract_precision(sql_type, precision)
      precision if [ODBC::SQL_DECIMAL, ODBC::SQL_NUMERIC].include?(sql_type)
    end

    # Ignore the ODBC scale of SQL types which don't take
    # an explicit scale when defining a column
    def extract_scale(sql_type, scale)
      scale || 0 if [ODBC::SQL_DECIMAL, ODBC::SQL_NUMERIC].include?(sql_type)
    end

    def numeric_type(scale, native_types)
      scale.nil? || scale == 0 ? :integer : (native_types[:decimal].nil? ? :float : :decimal)
    end
  end
end
