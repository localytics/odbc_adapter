module ODBCAdapter
  module Quoting
    # Quotes a string, escaping any ' (single quote) characters.
    def quote_string(string)
      string.gsub(/\'/, "''")
    end

    # Returns a quoted form of the column name.
    def quote_column_name(name)
      name = name.to_s
      quote_char = database_metadata.identifier_quote_char.to_s.strip

      return name if quote_char.length.zero?
      quote_char = quote_char[0]

      # Avoid quoting any already quoted name
      return name if name[0] == quote_char && name[-1] == quote_char

      # If upcase identifiers, only quote mixed case names.
      if database_metadata.upcase_identifiers?
        return name unless name =~ /([A-Z]+[a-z])|([a-z]+[A-Z])/
      end

      "#{quote_char.chr}#{name}#{quote_char.chr}"
    end

    # Ideally, we'd return an ODBC date or timestamp literal escape
    # sequence, but not all ODBC drivers support them.
    def quoted_date(value)
      if value.acts_like?(:time)
        zone_conversion_method = ActiveRecord::Base.default_timezone == :utc ? :getutc : :getlocal

        if value.respond_to?(zone_conversion_method)
          value = value.send(zone_conversion_method)
        end
        value.strftime('%Y-%m-%d %H:%M:%S') # Time, DateTime
      else
        value.strftime('%Y-%m-%d') # Date
      end
    end

    def lookup_cast_type_from_column(column) # :nodoc:
      puts "odbc_adapter  Quoting  lookup_cast_type_from_column"
      type_map.lookup(column.type)
    end

    def quote_hash(hash:)
      "OBJECT_CONSTRUCT(" + hash.map {|key, value| quote(key) + "," + quote(value)}.join(",") + ")"
    end

    def quote_array(array:)
      "ARRAY_CONSTRUCT(" + array.map { |element| quote(element) }.join(",") + ")"
    end

    def quote(value)
      if value.is_a? Hash then return quote_hash hash: value end
      if value.is_a? Array then return quote_array array: value end
      if value.is_a? Type::SnowflakeVariant then return value.quote self end
      super
    end
  end
end
