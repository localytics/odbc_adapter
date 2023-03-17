# frozen_string_literal: true

module ODBCAdapter
  class Column < ActiveRecord::ConnectionAdapters::Column
    attr_reader :native_type

    # Add the native_type accessor to allow the native DBMS to report back what
    # it uses to represent the column internally.
    # rubocop:disable Metrics/ParameterLists, Style/OptionalBooleanParameter
    def initialize(name, default, sql_type_metadata = nil, null = true, table_name = nil, native_type = nil)
      super(name, default, sql_type_metadata, null, table_name)
      @native_type = native_type
    end
    # rubocop:enable Metrics/ParameterLists, Style/OptionalBooleanParameter
  end
end
