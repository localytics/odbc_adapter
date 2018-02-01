# ODBCAdapter

[![Build Status](https://travis-ci.com/localytics/odbc_adapter.svg?token=kQUiABmGkzyHdJdMnCnv&branch=master)](https://travis-ci.com/localytics/odbc_adapter)

An ActiveRecord ODBC adapter.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'odbc_adapter'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install odbc_adapter

## Usage

## Development

After checking out the repo, run `bin/setup` to install dependencies. Next, configure your system with a PostgreSQL data source called `ODBCAdapterPostgreSQLTest` (you can alternatively set the environment variables `CONN_STR` or `DSN`). Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/localytics/odbc_adapter.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
