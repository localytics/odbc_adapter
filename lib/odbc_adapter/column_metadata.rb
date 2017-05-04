module ODBCAdapter
  class ColumnMetadata
    GENERICS = {
      primary_key: [ODBC::SQL_INTEGER, ODBC::SQL_SMALLINT],
      string:      [ODBC::SQL_VARCHAR],
      text:        [ODBC::SQL_LONGVARCHAR, ODBC::SQL_VARCHAR],
      integer:     [ODBC::SQL_INTEGER, ODBC::SQL_SMALLINT],
      decimal:     [ODBC::SQL_NUMERIC, ODBC::SQL_DECIMAL],
      float:       [ODBC::SQL_DOUBLE, ODBC::SQL_REAL],
      datetime:    [ODBC::SQL_TYPE_TIMESTAMP, ODBC::SQL_TIMESTAMP],
      timestamp:   [ODBC::SQL_TYPE_TIMESTAMP, ODBC::SQL_TIMESTAMP],
      time:        [ODBC::SQL_TYPE_TIME, ODBC::SQL_TIME, ODBC::SQL_TYPE_TIMESTAMP, ODBC::SQL_TIMESTAMP],
      date:        [ODBC::SQL_TYPE_DATE, ODBC::SQL_DATE, ODBC::SQL_TYPE_TIMESTAMP, ODBC::SQL_TIMESTAMP],
      binary:      [ODBC::SQL_LONGVARBINARY, ODBC::SQL_VARBINARY],
      boolean:     [ODBC::SQL_BIT, ODBC::SQL_TINYINT, ODBC::SQL_SMALLINT, ODBC::SQL_INTEGER]
    }.freeze

    attr_reader :adapter

    def initialize(adapter)
      @adapter = adapter
    end

    def native_database_types
      grouped = reported_types.group_by { |row| row[1] }

      GENERICS.each_with_object({}) do |(abstract, candidates), mapped|
        candidates.detect do |candidate|
          next unless grouped[candidate]
          mapped[abstract] = native_type_mapping(abstract, grouped[candidate])
        end
      end
    end

    private

    # Creates a Hash describing a mapping from an abstract type to a
    # DBMS native type for use by #native_database_types
    def native_type_mapping(abstract, rows)
      # The appropriate SQL for :primary_key is hard to derive as
      # ODBC doesn't provide any info on a DBMS's native syntax for
      # autoincrement columns. So we use a lookup instead.
      return adapter.class::PRIMARY_KEY if abstract == :primary_key
      selected_row = rows[0]

      # If more than one native type corresponds to the SQL type we're
      # handling, the type in the first descriptor should be the
      # best match, because the ODBC specification states that
      # SQLGetTypeInfo returns the results ordered by SQL type and then by
      # how closely the native type maps to that SQL type.
      # But, for :text and :binary, select the native type with the
      # largest capacity. (Compare SQLGetTypeInfo:COLUMN_SIZE values)
      selected_row = rows.max_by { |row| row[2] } if %i[text binary].include?(abstract)
      result = { name: selected_row[0] } # SQLGetTypeInfo: TYPE_NAME

      create_params = selected_row[5]
      # Depending on the column type, the CREATE_PARAMS keywords can
      # include length, precision or scale.
      if create_params && !create_params.strip.empty? && abstract != :decimal
        result[:limit] = selected_row[2] # SQLGetTypeInfo: COL_SIZE
      end

      result
    end

    def reported_types
      @reported_types ||=
        begin
          stmt = adapter.raw_connection.types
          stmt.fetch_all
        ensure
          stmt.drop unless stmt.nil?
        end
    end
  end
end
