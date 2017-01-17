$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'odbc_adapter'

require 'minitest/autorun'

ActiveRecord::Base.establish_connection(adapter: 'odbc', dsn: 'ODBCTestPostgres')

ActiveRecord::Schema.define do
  create_table :users, force: true do |t|
    t.string :first_name
    t.string :last_name
    t.integer :letters
    t.timestamps
  end
end

Fixtures = [
  { first_name: 'Kevin', last_name: 'Deisz', letters: 10 },
  { first_name: 'Michal', last_name: 'Klos', letters: 10 },
  { first_name: 'Jason', last_name: 'Dsouza', letters: 11 },
  { first_name: 'Ash', last_name: 'Hepburn', letters: 10 },
  { first_name: 'Sharif', last_name: 'Younes', letters: 12 },
  { first_name: 'Ryan', last_name: 'Brown', letters: 9 }
]

class User < ActiveRecord::Base
  create(Fixtures)
end
