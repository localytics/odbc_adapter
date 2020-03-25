# ODBCAdapter [![License][license-badge]][license-link]

| ActiveRecord | Gem Version | Branch | Status |
|--------------|-------------|--------|--------|
| `5.x`        | `~> '5.0'`  | [`master`][5.x-branch] | [![Build Status][5.x-build-badge]][build-link] |
| `4.x`        | `~> '4.0'`  | [`4.2.x`][4.x-branch]  | [![Build Status][4.x-build-badge]][build-link] |

## Supported Databases

- PostgreSQL 9
- MySQL 5
- Snowflake

You can also register your own adapter to get more support for your DBMS
`ODBCAdapter.register`.

## Installation

Ensure you have the ODBC driver installed on your machine. You will also need
the driver for whichever database to which you want ODBC to connect.

Add this line to your application's Gemfile:

```ruby
gem 'odbc_adapter'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install odbc_adapter

## Usage

Configure your `database.yml` by either using the `dsn` option to point to a DSN
that corresponds to a valid entry in your `~/.odbc.ini` file:

```yml
development:
  adapter:  odbc
  dsn: MyDatabaseDSN
```

or by using the `conn_str` option and specifying the entire connection string:

```yml
development:
  adapter: odbc
  conn_str: "DRIVER={PostgreSQL ANSI};SERVER=localhost;PORT=5432;DATABASE=my_database;UID=postgres;"
```

ActiveRecord models that use this connection will now be connecting to the
configured database using the ODBC driver.

### Extending

Configure your own adapter by registering it in your application's bootstrap
process. For example, you could add the following to a Rails application via
`config/initializers/custom_database_adapter.rb`

```ruby
ODBCAdapter.register(/custom/, ActiveRecord::ConnectionAdapters::ODBCAdapter) do
  # Overrides
end
```

```yml
development:
  adapter: odbc
  dsn: CustomDB
```

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

## Contributing

Bug reports and pull requests are welcome on [GitHub][github-repo].

## Prior Work

A lot of this work is based on [OpenLink's ActiveRecord adapter][openlink-activerecord-adapter] which works for earlier versions of Rails. 5.0.x compatability work was completed by the [Localytics][localytics-github] team.

[4.x-branch]: https://github.com/localytics/odbc_adapter/tree/v4.2.x
[4.x-build-badge]: https://travis-ci.org/localytics/odbc_adapter.svg?branch=4.2.x
[5.x-branch]: https://github.com/localytics/odbc_adapter/tree/master
[5.x-build-badge]: https://travis-ci.org/localytics/odbc_adapter.svg?branch=master
[build-link]: https://travis-ci.org/localytics/odbc_adapter/branches
[github-repo]: https://github.com/localytics/odbc_adapter
[license-badge]: https://img.shields.io/github/license/localytics/odbc_adapter.svg
[license-link]: https://github.com/localytics/odbc_adapter/blob/master/LICENSE
[localytics-github]: https://github.com/localytics
[openlink-activerecord-adapter]: https://github.com/dosire/activerecord-odbc-adapter
[supported-versions-badge]: https://img.shields.io/badge/active__record-4.x--5.x-green.svg
