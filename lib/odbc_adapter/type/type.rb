require 'odbc_adapter/type/array_of'
require 'odbc_adapter/type/object'
require 'odbc_adapter/type/variant'
require 'odbc_adapter/type/snowflake_integer'

require 'odbc_adapter/type/internal/snowflake_variant'

module ODBCAdapter
  module Type
    ArrayOfBigIntegers = array_of(ActiveRecord::Type::BigInteger.new)
    ArrayOfBinaries = array_of(ActiveRecord::Type::Binary.new)
    ArrayOfBooleans = array_of(ActiveRecord::Type::Boolean.new)
    ArrayOfDates = array_of(ActiveRecord::Type::Date.new)
    ArrayOfDateTimes = array_of(ActiveRecord::Type::DateTime.new)
    ArrayOfDecimals = array_of(ActiveRecord::Type::Decimal.new)
    ArrayOfFloats = array_of(ActiveRecord::Type::Float.new)
    ArrayOfImmutableStrings = array_of(ActiveRecord::Type::ImmutableString.new)
    ArrayOfIntegers = array_of(ActiveRecord::Type::Integer.new)
    ArrayOfStrings = array_of(ActiveRecord::Type::String.new)
    ArrayOfTimes = array_of(ActiveRecord::Type::Time.new)
    ArrayOfValues = array_of(ActiveRecord::Type::Value.new)

    ActiveRecord::Type.register(:array_of_big_integers, ArrayOfBigIntegers, adapter: :odbc)
    ActiveRecord::Type.register(:array_of_binaries, ArrayOfBinaries, adapter: :odbc)
    ActiveRecord::Type.register(:array_of_booleans, ArrayOfBooleans, adapter: :odbc)
    ActiveRecord::Type.register(:array_of_dates, ArrayOfDates, adapter: :odbc)
    ActiveRecord::Type.register(:array_of_date_times, ArrayOfDateTimes, adapter: :odbc)
    ActiveRecord::Type.register(:array_of_decimals, ArrayOfDecimals, adapter: :odbc)
    ActiveRecord::Type.register(:array_of_floats, ArrayOfFloats, adapter: :odbc)
    ActiveRecord::Type.register(:array_of_immutable_strings, ArrayOfImmutableStrings, adapter: :odbc)
    ActiveRecord::Type.register(:array_of_integers, ArrayOfIntegers, adapter: :odbc)
    ActiveRecord::Type.register(:array_of_strings, ArrayOfStrings, adapter: :odbc)
    ActiveRecord::Type.register(:array_of_times, ArrayOfTimes, adapter: :odbc)
    ActiveRecord::Type.register(:array_of_values, ArrayOfValues, adapter: :odbc)

    ActiveRecord::Type.register(:object, Object, adapter: :odbc)

    ActiveRecord::Type.register(:variant, Variant, adapter: :odbc)

    ActiveRecord::Type.register(:integer, SnowflakeInteger, adapter: :odbc)
  end
end
