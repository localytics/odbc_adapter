module ODBCAdapter
  class DBMS
    module OracleExt
      class BindSubstitution < Arel::Visitors::Oracle
        include Arel::Visitors::BindVisitor
      end

      # Ideally, we'd return an ODBC date or timestamp literal escape
      # sequence, but not all ODBC drivers support them.
      def quoted_date(value)
        if value.acts_like?(:time) # Time, DateTime
          "to_timestamp(\'#{value.strftime("%Y-%m-%d %H:%M:%S")}\', \'YYYY-MM-DD HH24:MI:SS\')"
        else # Date
          "to_timestamp(\'#{value.strftime("%Y-%m-%d")}\', \'YYYY-MM-DD\')"
        end
      end

      # Some ActiveRecord tests insert using an explicit id value. Starting the
      # primary key sequence from 10000 eliminates collisions (and subsequent
      # complaints from Oracle of integrity constraint violations) between id's
      # generated from the sequence and explicitly supplied ids.
      # Using explicit and generated id's together should be avoided.
      def create_table(name, options = {})
        response = super(name, options)
        execute("CREATE SEQUENCE #{name}_seq START WITH 10000") unless options[:id] == false
        response
      end

      # Renames a table.
      def rename_table(name, new_name)
        execute("RENAME #{name} TO #{new_name}")
        execute("RENAME #{name}_seq TO #{new_name}_seq")
      end

      def drop_table(name, options = {})
        super(name, options)
        execute("DROP SEQUENCE #{name}_seq")
      end

      def change_column(table_name, column_name, type, options = {})
        change_column_sql = "ALTER TABLE #{table_name} MODIFY #{column_name} #{type_to_sql(type, options[:limit], options[:precision], options[:scale])}"
        add_column_options!(change_column_sql, options)
        execute(change_column_sql)
      end

      def rename_column(table_name, column_name, new_column_name)
        execute("ALTER TABLE #{table_name} RENAME COLUMN #{column_name} to #{new_column_name}")
      end

      def structure_dump
        seqs =
          select_all("select sequence_name from user_sequences").inject("") do |structure, seq|
            structure << "create sequence #{seq.to_a.first.last};\n\n"
          end

        select_all("select table_name from user_tables").inject(seqs) do |structure, table|
          table_name = table.to_a.first.last
          column_metadata_sql = %Q{
            select column_name, data_type, data_length, data_precision, data_scale, data_default, nullable
            from user_tab_columns
            where table_name = '#{table_name}'
            order by column_id
          }

          ddl = "create table #{table_name} (\n "
          ddl << select_all(column_metadata_sql).map { |row| structure_dump_column(row) }.join(",\n ")
          ddl << ");\n\n"
          structure << ddl
        end
      end

      private

      def structure_dump_column(row)
        col = "#{row['column_name'].downcase} #{row['data_type'].downcase}"
        if row['data_type'] =='NUMBER' and !row['data_precision'].nil?
          col << "(#{row['data_precision'].to_i}"
          col << ",#{row['data_scale'].to_i}" if !row['data_scale'].nil?
          col << ')'
        elsif row['data_type'].include?('CHAR')
          col << "(#{row['data_length'].to_i})"
        end

        col << " default #{row['data_default']}" if !row['data_default'].nil?
        col << ' not null' if row['nullable'] == 'N'
        col
      end
    end
  end
end
