# frozen_string_literal: true

module ODBCAdapter
  module Adapters
    module Snowflake
      module SchemaStatements
        # Returns an array of table names, for database tables visible on the
        # current connection.
        def tables(_name = nil)
          @connection.exec_query("select table_name from information_schema.tables where table_schema != 'INFORMATION_SCHEMA' and table_type = 'BASE TABLE'")
                     .rows
                     .map do |name_col|
            format_case(name_col.first)
          end
        end

        # Returns an array of view names defined in the database.
        def views
          @connection.exec_query("select table_name from information_schema.views where table_schema != 'INFORMATION_SCHEMA'")
                     .rows
                     .map do |name_col|
            format_case(name_col.first)
          end
        end

        # Returns an array of indexes for the given table.
        # We currently don't have indexes in snowflake - Once we do, this should be updated. Probably something like (unsure):
        # @connection.exec_query("select * from information_schema.table_constraints where constraint_type = 'INDEX'").rows.map(&:first)
        def indexes(_table_name, _name = nil)
          []
        end

        # Returns an array of Column objects for the table specified by
        # +table_name+.
        def columns(table_name, _name = nil)
          # Prepared statements need to be fixed, so just interpolate for now. No user input here; should be fine.
          @connection.exec_query("select column_name, column_default, data_type, character_maximum_length, numeric_scale, numeric_precision, is_nullable from information_schema.columns where table_schema != 'INFORMATION_SCHEMA' and table_name = '#{native_case(table_name.to_s)}'")
                     .rows
                     .map do |col|
            col_name        = col[0]  # SQLColumns: COLUMN_NAME
            col_default     = col[1]  # SQLColumns: COLUMN_DEFAULT
            col_sql_type    = col[2]  # SQLColumns: DATA_TYPE
            col_limit       = col[3]  # SQLColumns: CHARACTER_MAXIMUM_LENGTH
            col_scale       = col[4]  # SQLColumns: NUMERIC_SCALE
            col_precision   = col[5]  # SQLColumns: NUMERIC_PRECISION
            col_nullable    = col[6]  # SQLColumns: IS_NULLABLE

            # No need to coerce 'bool' to 'boolean', Snowflake uses 'BOOLEAN'
            args = { sql_type: col_sql_type, type: col_sql_type, limit: col_limit }

            # Snowflake uses NUMBER for all numeric columns, so it seems
            if col_sql_type == 'NUMBER'
              args[:scale]     = col_scale || 0
              args[:precision] = col_precision
            end
            sql_type_metadata = ActiveRecord::ConnectionAdapters::SqlTypeMetadata.new(**args)

            new_column(format_case(col_name), col_default, sql_type_metadata, col_nullable, table_name, col_sql_type)
          end
        end

        # Returns just a table's primary key
        # We currently don't have primary keys in snowflake - Once we do, this should be updated. Probably something like (unsure):
        # @connection.exec_query("select clustering_key from information_schema.tables where table_name = '#{table_name}'")
        def primary_key(_table_name)
          nil
        end

        # We currently don't have fks in snowflake - Once we do, this should be updated. Probably something like (unsure):
        # @connection.exec_query("select * from information_schema.referential_constraints where constraint_type = 'FOREIGN KEY'").rows.map(&:first)
        def foreign_keys(_table_name)
          []
        end
      end
    end
  end
end
