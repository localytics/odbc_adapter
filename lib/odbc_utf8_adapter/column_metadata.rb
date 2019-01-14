module ODBCUTF8Adapter
  class ColumnMetadata
    GENERICS = {
      primary_key: [ODBC_UTF8::SQL_INTEGER, ODBC_UTF8::SQL_SMALLINT],
      string:      [ODBC_UTF8::SQL_VARCHAR],
      text:        [ODBC_UTF8::SQL_LONGVARCHAR, ODBC_UTF8::SQL_VARCHAR],
      integer:     [ODBC_UTF8::SQL_INTEGER, ODBC_UTF8::SQL_SMALLINT],
      decimal:     [ODBC_UTF8::SQL_NUMERIC, ODBC_UTF8::SQL_DECIMAL],
      float:       [ODBC_UTF8::SQL_DOUBLE, ODBC_UTF8::SQL_REAL],
      datetime:    [ODBC_UTF8::SQL_TYPE_TIMESTAMP, ODBC_UTF8::SQL_TIMESTAMP],
      timestamp:   [ODBC_UTF8::SQL_TYPE_TIMESTAMP, ODBC_UTF8::SQL_TIMESTAMP],
      time:        [ODBC_UTF8::SQL_TYPE_TIME, ODBC_UTF8::SQL_TIME, ODBC_UTF8::SQL_TYPE_TIMESTAMP, ODBC_UTF8::SQL_TIMESTAMP],
      date:        [ODBC_UTF8::SQL_TYPE_DATE, ODBC_UTF8::SQL_DATE, ODBC_UTF8::SQL_TYPE_TIMESTAMP, ODBC_UTF8::SQL_TIMESTAMP],
      binary:      [ODBC_UTF8::SQL_LONGVARBINARY, ODBC_UTF8::SQL_VARBINARY],
      boolean:     [ODBC_UTF8::SQL_BIT, ODBC_UTF8::SQL_TINYINT, ODBC_UTF8::SQL_SMALLINT, ODBC_UTF8::SQL_INTEGER]
    }

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
      selected_row = rows.max_by { |row| row[2] } if [:text, :binary].include?(abstract)
      result = { name: selected_row[0] } # SQLGetTypeInfo: TYPE_NAME

      create_params = selected_row[5]
      # Depending on the column type, the CREATE_PARAMS keywords can
      # include length, precision or scale.
      if create_params && create_params.strip.length > 0 && abstract != :decimal
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
