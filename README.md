# ODBCAdapter

An ActiveRecord ODBC adapter. Pattern has made some updates to get this working with Rails 6 as forked from repo was not actively being maintained to do so.

This adapter will work for basic queries for most DBMSs out of the box, without support for migrations. Full support is built-in for MySQL 5 and PostgreSQL 9 databases. You can register your own adapter to get more support for your DBMS using the `ODBCAdapter.register` function.

A lot of this work is based on [OpenLink's ActiveRecord adapter](http://odbc-rails.rubyforge.org/) which works for earlier versions of Rails.

## Installation

Ensure you have the ODBC driver installed on your machine. You will also need the driver for whichever database to which you want ODBC to connect.

Add this line to your application's Gemfile:

```ruby
gem 'odbc_adapter'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install odbc_adapter

## Usage

Configure your `database.yml` by either using the `dsn` option to point to a DSN that corresponds to a valid entry in your `~/.odbc.ini` file:

```
development:
  adapter:  odbc
  dsn: MyDatabaseDSN
```

or by using the `conn_str` option and specifying the entire connection string:

```
development:
  adapter: odbc
  conn_str: "DRIVER={PostgreSQL ANSI};SERVER=localhost;PORT=5432;DATABASE=my_database;UID=postgres;"
```

ActiveRecord models that use this connection will now be connecting to the configured database using the ODBC driver.

## Testing

To run the tests, you'll need the ODBC driver as well as the connection adapter for each database against which you're trying to test. Then run `DSN=MyDatabaseDSN bundle exec rake test` and the test suite will be run by connecting to your database.

## Testing Using a Docker Container Because ODBC on Mac is Hard

Tested on Sierra.


Run from project root:

```
bundle package
docker build -f Dockerfile.dev -t odbc-dev .

# Local mount mysql directory to avoid some permissions problems
mkdir -p /tmp/mysql
docker run -it --rm -v $(pwd):/workspace -v /tmp/mysql:/var/lib/mysql odbc-dev:latest

# In container
docker/test.sh
```

## Datatype References


Reference https://docs.snowflake.com/en/sql-reference/intro-summary-data-types

https://github.com/rails/rails/blob/main/activerecord/lib/active_record/connection_adapters/abstract_adapter.rb#L877-L908

```
["number",
 "decimal",
 "numeric",
 "int",
 "integer",
 "bigint",
 "smallint",
 "tinyint",
 "byteint",
 "float",
 "float4",
 "float8",
 "double",
 "real",
 "varchar",
 "char",
 "character",
 "string",
 "text",
 "binary",
 "varbinary",
 "boolean",
 "date",
 "datetime",
 "time",
 "timestamp",
 "timestamp_ltz",
 "timestamp_ntz",
 "timestamp_tz",
 "variant",
 "object",
 "array",
 "geography",
 "geometry"]
```


Possible mapping from chatgpt

| Snowflake Data Type   | Ruby ActiveRecord Type | PostgreSQL Type  |
| --------------------- | ---------------------- | ---------------- |
| number                | :decimal               |  numeric
| decimal               | :decimal               |  numeric
| numeric               | :decimal               |  numeric
| int                   | :integer               |  integer
| integer               | :integer               |  integer
| bigint                | :bigint                |  bigint
| smallint              | :integer               |  smallint
| tinyint               | :integer               |  smallint
| byteint               | :integer               |  smallint
| float                 | :float                 |  double precision
| float4                | :float                 |  real
| float8                | :float                 |  double precision
| double                | :float                 |  double precision
| real                  | :float                 |  real
| varchar               | :string                |  character varying
| char                  | :string                |  character
| character             | :string                |  character
| string                | :string                |  character varying
| text                  | :text                  |  text
| binary                | :binary                |  bytea
| varbinary             | :binary                |  bytea
| boolean               | :boolean               |  boolean
| date                  | :date                  |  date
| datetime              | :datetime              |  timestamp without time zone
| time                  | :time                  |  time without time zone
| timestamp             | :timestamp             |  timestamp without time zone
| timestamp_ltz         | :timestamp             |  timestamp without time zone
| timestamp_ntz         | :timestamp             |  timestamp without time zone
| timestamp_tz          | :timestamp             |  timestamp with time zone
| variant               | :jsonb                 |  jsonb
| object                | :jsonb                 |  jsonb
| array                 | :jsonb                 |  jsonb
| geography             | :st_point, :st_polygon,|  geography
|                       | :st_multipolygon       |
| geometry              | :st_point, :st_polygon,|  geometry
|                       | :st_multipolygon       |


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/localytics/odbc_adapter.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
