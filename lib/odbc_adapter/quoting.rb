module ODBCAdapter
  module Quoting
    # Quotes the column value to help prevent
    # {SQL injection attacks}[http://en.wikipedia.org/wiki/SQL_injection].
    def quote(value, column = nil)
      # records are quoted as their primary key
      return value.quoted_id if value.respond_to?(:quoted_id)

      case value
      when String, ActiveSupport::Multibyte::Chars
        value = value.to_s
        return "'#{quote_string(value)}'" unless column

        case column.type
        when :binary then "'#{quote_string(column.string_to_binary(value))}'"
        when :integer then value.to_i.to_s
        when :float then value.to_f.to_s
        else
          "'#{quote_string(value)}'"
        end

      when true, false
        if column && column.type == :integer
          value ? '1' : '0'
        else
          value ? quoted_true : quoted_false
        end
        # BigDecimals need to be put in a non-normalized form and quoted.
      when nil        then "NULL"
      when BigDecimal then value.to_s('F')
      when Numeric    then value.to_s
      when Symbol     then "'#{quote_string(value.to_s)}'"
      else
        if value.acts_like?(:date) || value.acts_like?(:time)
          quoted_date(value)
        else
          super
        end
      end
    end

    # Quotes a string, escaping any ' (single quote) characters.
    def quote_string(string)
      string.gsub(/\'/, "''")
    end

    # Returns a quoted form of the column name.
    def quote_column_name(name)
      name = name.to_s
      quote_char = dbms.field_for(ODBC::SQL_IDENTIFIER_QUOTE_CHAR).to_s.strip

      return name if quote_char.length.zero?
      quote_char = quote_char[0]

      # Avoid quoting any already quoted name
      return name if name[0] == quote_char && name[-1] == quote_char

      # If DBMS's SQL_IDENTIFIER_CASE = SQL_IC_UPPER, only quote mixed
      # case names.
      if dbms.field_for(ODBC::SQL_IDENTIFIER_CASE) == ODBC::SQL_IC_UPPER
        return name unless (name =~ /([A-Z]+[a-z])|([a-z]+[A-Z])/)
      end

      "#{quote_char.chr}#{name}#{quote_char.chr}"
    end

    def quoted_true
      '1'
    end

    # Ideally, we'd return an ODBC date or timestamp literal escape
    # sequence, but not all ODBC drivers support them.
    def quoted_date(value)
      if value.acts_like?(:time) # Time, DateTime
        "'#{value.strftime("%Y-%m-%d %H:%M:%S")}'"
      else # Date
        "'#{value.strftime("%Y-%m-%d")}'"
      end
    end
  end
end
