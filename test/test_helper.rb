$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'odbc_adapter'

require 'minitest/autorun'

options = { adapter: 'odbc' }
options[:conn_str] = ENV['CONN_STR'] if ENV['CONN_STR']
options[:dsn]      = ENV['DSN'] if ENV['DSN']
options[:dsn]      = 'ODBCAdapterPostgreSQLTest' if options.values_at(:conn_str, :dsn).compact.empty?

ActiveRecord::Base.establish_connection(options)

ActiveRecord::Schema.define do
  create_table :users, force: true do |t|
    t.string :first_name
    t.string :last_name
    t.integer :letters
    t.timestamps
  end

  create_table :todos, force: true do |t|
    t.integer :user_id
    t.text :body
    t.timestamps
  end
end

class User < ActiveRecord::Base
  has_many :todos, dependent: :destroy

  scope :lots_of_letters, -> { where(arel_table[:letters].gt(10)) }

  create([
    { first_name: 'Kevin', last_name: 'Deisz', letters: 10 },
    { first_name: 'Michal', last_name: 'Klos', letters: 10 },
    { first_name: 'Jason', last_name: 'Dsouza', letters: 11 },
    { first_name: 'Ash', last_name: 'Hepburn', letters: 10 },
    { first_name: 'Sharif', last_name: 'Younes', letters: 12 },
    { first_name: 'Ryan', last_name: 'Brown', letters: 9 }
  ])
end

class Todo < ActiveRecord::Base
  belongs_to :user
end

User.find(1).todos.create([
  { body: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.' },
  { body: 'Praesent ut dolor nec eros euismod hendrerit.' },
  { body: 'Curabitur lacinia metus eget interdum volutpat.' }
])

User.find(2).todos.create([
  { body: 'Nulla sollicitudin venenatis turpis vitae finibus.' },
  { body: 'Proin consectetur id lacus vel feugiat.' },
  { body: 'Pellentesque augue orci, aliquet nec ipsum ultrices, cursus blandit metus.' },
  { body: 'Nulla posuere nisl risus, eget scelerisque leo congue non.' },
  { body: 'Curabitur eget massa mollis, iaculis risus in, tristique metus.' }
])

User.find(4).todos.create([
  { body: 'In hac habitasse platea dictumst.' },
  { body: 'Integer molestie ornare velit, eu interdum felis euismod vitae.' }
])
