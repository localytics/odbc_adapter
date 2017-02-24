module ODBCAdapter
  module Adapters
    # Overrides specific to PostgreSQL. Mostly taken from
    # ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
    class PostgreSQLODBCAdapter < ActiveRecord::ConnectionAdapters::ODBCAdapter
      BOOLEAN_TYPE = 'bool'.freeze
      PRIMARY_KEY  = 'SERIAL PRIMARY KEY'.freeze

      alias create insert

      # Override to handle booleans appropriately
      def native_database_types
        @native_database_types ||= super.merge(boolean: { name: 'bool' })
      end

      def arel_visitor
        Arel::Visitors::PostgreSQL.new(self)
      end

      # Filter for ODBCAdapter#tables
      # Omits table from #tables if table_filter returns true
      def table_filtered?(schema_name, table_type)
        %w[information_schema pg_catalog].include?(schema_name) || table_type !~ /TABLE/i
      end

      def truncate(table_name, name = nil)
        exec_query("TRUNCATE TABLE #{quote_table_name(table_name)}", name)
      end

      # Returns the sequence name for a table's primary key or some other
      # specified key.
      def default_sequence_name(table_name, pk = nil)
        serial_sequence(table_name, pk || 'id').split('.').last
      rescue ActiveRecord::StatementInvalid
        "#{table_name}_#{pk || 'id'}_seq"
      end

      def sql_for_insert(sql, pk, _id_value, _sequence_name, binds)
        unless pk
          table_ref = extract_table_ref_from_insert_sql(sql)
          pk = primary_key(table_ref) if table_ref
        end

        sql = "#{sql} RETURNING #{quote_column_name(pk)}" if pk
        [sql, binds]
      end

      def type_cast(value, column)
        return super unless column

        case value
        when String
          return super unless 'bytea' == column.native_type
          { value: value, format: 1 }
        else
          super
        end
      end

      # Quotes a string, escaping any ' (single quote) and \ (backslash)
      # characters.
      def quote_string(string)
        string.gsub(/\\/, '\&\&').gsub(/'/, "''")
      end

      def disable_referential_integrity
        execute(tables.map { |name| "ALTER TABLE #{quote_table_name(name)} DISABLE TRIGGER ALL" }.join(';'))
        yield
      ensure
        execute(tables.map { |name| "ALTER TABLE #{quote_table_name(name)} ENABLE TRIGGER ALL" }.join(';'))
      end

      # Create a new PostgreSQL database. Options include <tt>:owner</tt>,
      # <tt>:template</tt>, <tt>:encoding</tt>, <tt>:tablespace</tt>, and
      # <tt>:connection_limit</tt> (note that MySQL uses <tt>:charset</tt>
      # while PostgreSQL uses <tt>:encoding</tt>).
      #
      # Example:
      #   create_database config[:database], config
      #   create_database 'foo_development', encoding: 'unicode'
      def create_database(name, options = {})
        options = options.reverse_merge(encoding: 'utf8')

        option_string = options.symbolize_keys.sum do |key, value|
          case key
          when :owner
            " OWNER = \"#{value}\""
          when :template
            " TEMPLATE = \"#{value}\""
          when :encoding
            " ENCODING = '#{value}'"
          when :tablespace
            " TABLESPACE = \"#{value}\""
          when :connection_limit
            " CONNECTION LIMIT = #{value}"
          else
            ''
          end
        end

        execute("CREATE DATABASE #{quote_table_name(name)}#{option_string}")
      end

      # Drops a PostgreSQL database.
      #
      # Example:
      #   drop_database 'rails_development'
      def drop_database(name)
        execute "DROP DATABASE IF EXISTS #{quote_table_name(name)}"
      end

      # Renames a table.
      def rename_table(name, new_name)
        execute("ALTER TABLE #{quote_table_name(name)} RENAME TO #{quote_table_name(new_name)}")
      end

      def change_column(table_name, column_name, type, options = {})
        execute("ALTER TABLE #{table_name} ALTER  #{column_name} TYPE #{type_to_sql(type, options[:limit], options[:precision], options[:scale])}")
        change_column_default(table_name, column_name, options[:default]) if options_include_default?(options)
      end

      def change_column_default(table_name, column_name, default)
        execute("ALTER TABLE #{table_name} ALTER COLUMN #{column_name} SET DEFAULT #{quote(default)}")
      end

      def rename_column(table_name, column_name, new_column_name)
        execute("ALTER TABLE #{table_name} RENAME #{column_name} TO #{new_column_name}")
      end

      def remove_index!(_table_name, index_name)
        execute("DROP INDEX #{quote_table_name(index_name)}")
      end

      def rename_index(_table_name, old_name, new_name)
        execute("ALTER INDEX #{quote_column_name(old_name)} RENAME TO #{quote_table_name(new_name)}")
      end

      # Returns a SELECT DISTINCT clause for a given set of columns and a given
      # ORDER BY clause.
      #
      # PostgreSQL requires the ORDER BY columns in the select list for
      # distinct queries, and requires that the ORDER BY include the distinct
      # column.
      #
      #   distinct("posts.id", "posts.created_at desc")
      def distinct(columns, orders)
        return "DISTINCT #{columns}" if orders.empty?

        # Construct a clean list of column names from the ORDER BY clause,
        # removing any ASC/DESC modifiers
        order_columns = orders.map { |s| s.gsub(/\s+(ASC|DESC)\s*(NULLS\s+(FIRST|LAST)\s*)?/i, '') }
        order_columns.reject!(&:blank?)
        order_columns = order_columns.zip((0...order_columns.size).to_a).map { |s, i| "#{s} AS alias_#{i}" }

        "DISTINCT #{columns}, #{order_columns * ', '}"
      end

      protected

      # Executes an INSERT query and returns the new record's ID
      def insert_sql(sql, name = nil, pk = nil, id_value = nil, sequence_name = nil)
        unless pk
          table_ref = extract_table_ref_from_insert_sql(sql)
          pk = primary_key(table_ref) if table_ref
        end

        if pk
          select_value("#{sql} RETURNING #{quote_column_name(pk)}")
        else
          super
        end
      end

      # Returns the current ID of a table's sequence.
      def last_insert_id(sequence_name)
        r = exec_query("SELECT currval('#{sequence_name}')", 'SQL')
        Integer(r.rows.first.first)
      end

      private

      def serial_sequence(table, column)
        result = exec_query(<<-eosql, 'SCHEMA')
          SELECT pg_get_serial_sequence('#{table}', '#{column}')
        eosql
        result.rows.first.first
      end
    end
  end
end
