lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'odbc_adapter/version'

Gem::Specification.new do |spec|
  spec.name          = 'odbc_adapter'
  spec.version       = ODBCAdapter::VERSION
  spec.authors       = ['Localytics']
  spec.email         = ['oss@localytics.com']

  spec.summary       = 'An ActiveRecord ODBC adapter'
  spec.homepage      = 'https://github.com/localytics/odbc_adapter'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activerecord', '>= 5.2.1'
  spec.add_dependency 'ruby-odbc', '~> 0.9'

  spec.add_development_dependency 'bundler', '~> 1.14'
  spec.add_development_dependency 'minitest', '~> 5.10'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rubocop', '0.48.1'
  spec.add_development_dependency 'simplecov', '~> 0.14'
  spec.add_development_dependency 'pry', '~> 0.11.1'
end
