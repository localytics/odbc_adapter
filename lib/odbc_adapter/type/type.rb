require 'odbc_adapter/type/array_of'
require 'odbc_adapter/type/object'
require 'odbc_adapter/type/variant'

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

    ActiveRecord::Type.register(:array_of_big_integers, ArrayOfBigIntegers)
    ActiveRecord::Type.register(:array_of_binaries, ArrayOfBinaries)
    ActiveRecord::Type.register(:array_of_booleans, ArrayOfBooleans)
    ActiveRecord::Type.register(:array_of_dates, ArrayOfDates)
    ActiveRecord::Type.register(:array_of_date_times, ArrayOfDateTimes)
    ActiveRecord::Type.register(:array_of_decimals, ArrayOfDecimals)
    ActiveRecord::Type.register(:array_of_floats, ArrayOfFloats)
    ActiveRecord::Type.register(:array_of_immutable_strings, ArrayOfImmutableStrings)
    ActiveRecord::Type.register(:array_of_integers, ArrayOfIntegers)
    ActiveRecord::Type.register(:array_of_strings, ArrayOfStrings)
    ActiveRecord::Type.register(:array_of_times, ArrayOfTimes)
    ActiveRecord::Type.register(:array_of_values, ArrayOfValues)

    ActiveRecord::Type.register(:object, Object)

    ActiveRecord::Type.register(:variant, Variant)
  end
end
