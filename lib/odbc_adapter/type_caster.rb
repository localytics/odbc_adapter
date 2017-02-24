module ODBCAdapter
  class TypeCaster
    # When fetching a result set, the Ruby ODBC driver converts all ODBC
    # SQL types to an equivalent Ruby type; with the exception of
    # SQL_DATE, SQL_TIME and SQL_TIMESTAMP.
    TYPES = [
      ODBC::SQL_DATE,
      ODBC::SQL_TIME,
      ODBC::SQL_TIMESTAMP
    ].freeze

    attr_reader :idx

    def initialize(idx)
      @idx = idx
    end

    def cast(value)
      case value
      when ODBC::TimeStamp
        Time.gm(value.year, value.month, value.day, value.hour, value.minute, value.second)
      when ODBC::Time
        now = DateTime.now
        Time.gm(now.year, now.month, now.day, value.hour, value.minute, value.second)
      when ODBC::Date
        Date.new(value.year, value.month, value.day)
      else
        value
      end
    rescue
      # Handle pre-epoch dates
      DateTime.new(value.year, value.month, value.day, value.hour, value.minute, value.second)
    end

    # Build a list of casters from a list of columns
    def self.build_from(columns)
      columns.each_with_index.each_with_object([]) do |(column, idx), casters|
        casters << new(idx) if TYPES.include?(column.type)
      end
    end
  end
end
