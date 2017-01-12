module ODBCAdapter
  class DBMS
    # Overrides specific to PostgreSQL. Mostly taken from
    # ActiveRecord::ConnectionAdapters::MySQLAdapter
    module MySQLExt
      class BindSubstitution < Arel::Visitors::MySQL
        include Arel::Visitors::BindVisitor
      end

      PRIMARY_KEY = 'INT(11) NOT NULL AUTO_INCREMENT PRIMARY KEY'

      def limited_update_conditions(where_sql, _quoted_table_name, _quoted_primary_key)
        where_sql
      end

      # Taken from ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter
      def join_to_update(update, select) #:nodoc:
        if select.limit || select.offset || select.orders.any?
          subsubselect = select.clone
          subsubselect.projections = [update.key]

          subselect = Arel::SelectManager.new(select.engine)
          subselect.project Arel.sql(update.key.name)
          subselect.from subsubselect.as('__active_record_temp')

          update.where update.key.in(subselect)
        else
          update.table select.source
          update.wheres = select.constraints
        end
      end

      # Quotes a string, escaping any ' (single quote) and \ (backslash)
      # characters.
      def quote_string(string)
        string.gsub(/\\/, '\&\&').gsub(/'/, "''")
      end

      def disable_referential_integrity(&block) #:nodoc:
        old = select_value("SELECT @@FOREIGN_KEY_CHECKS")

        begin
          update("SET FOREIGN_KEY_CHECKS = 0")
          yield
        ensure
          update("SET FOREIGN_KEY_CHECKS = #{old}")
        end
      end

      # Create a new MySQL database with optional <tt>:charset</tt> and <tt>:collation</tt>.
      # Charset defaults to utf8.
      #
      # Example:
      #   create_database 'charset_test', :charset => 'latin1', :collation => 'latin1_bin'
      #   create_database 'matt_development'
      #   create_database 'matt_development', :charset => :big5
      def create_database(name, options = {})
        if options[:collation]
          execute("CREATE DATABASE `#{name}` DEFAULT CHARACTER SET `#{options[:charset] || 'utf8'}` COLLATE `#{options[:collation]}`")
        else
          execute("CREATE DATABASE `#{name}` DEFAULT CHARACTER SET `#{options[:charset] || 'utf8'}`")
        end
      end

      # Drops a MySQL database.
      #
      # Example:
      #   drop_database('sebastian_development')
      def drop_database(name) #:nodoc:
        execute("DROP DATABASE IF EXISTS `#{name}`")
      end

      def create_table(name, options = {})
        super(name, { options: 'ENGINE=InnoDB' }.merge(options))
      end

      # Renames a table.
      def rename_table(name, new_name)
        execute("RENAME TABLE #{quote_table_name(name)} TO #{quote_table_name(new_name)}")
      end

      def change_column(table_name, column_name, type, options = {})
        # column_name.to_s used in case column_name is a symbol
        unless options_include_default?(options)
          options[:default] = columns(table_name).find { |c| c.name == column_name.to_s }.default
        end

        change_column_sql = "ALTER TABLE #{table_name} CHANGE #{column_name} #{column_name} #{type_to_sql(type, options[:limit], options[:precision], options[:scale])}"
        add_column_options!(change_column_sql, options)
        execute(change_column_sql)
      end

      def change_column_default(table_name, column_name, default)
        col = columns(table_name).detect { |c| c.name == column_name.to_s }
        change_column(table_name, column_name, col.type,
          default: default, limit: col.limit, precision: col.precision, scale: col.scale)
      end

      def rename_column(table_name, column_name, new_column_name)
        col = columns(table_name).detect { |c| c.name == column_name.to_s }
        current_type = col.sql_type
        current_type << "(#{col.limit})" if col.limit
        execute("ALTER TABLE #{table_name} CHANGE #{column_name} #{new_column_name} #{current_type}")
      end

      def indexes(table_name, name = nil)
        # Skip primary key indexes
        super(table_name, name).delete_if { |i| i.unique && i.name =~ /^PRIMARY$/ }
      end

      def options_include_default?(options)
        # MySQL 5.x doesn't allow DEFAULT NULL for first timestamp column in a table
        if options.include?(:default) && options[:default].nil?
          if options.include?(:column) && options[:column].sql_type =~ /timestamp/i
            options.delete(:default)
          end
        end
        super(options)
      end

      def structure_dump
        select_all("SHOW FULL TABLES WHERE Table_type = 'BASE TABLE'").map do |table|
          table.delete('Table_type')
          sql = "SHOW CREATE TABLE #{quote_table_name(table.to_a.first.last)}"
          exec_query(sql).first['Create Table'] + ";\n\n"
        end.join
      end

      protected

      def insert_sql(sql, name = nil, pk = nil, id_value = nil, sequence_name = nil)
        super
        id_value || last_inserted_id(nil)
      end

      def last_inserted_id(_result)
        @connection.last_id
      end
    end
  end
end
