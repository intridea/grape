# frozen_string_literal: true

# when changing this file, run appraisal install ; rubocop -a gemfiles/*.gemfile

source('https://rubygems.org')

gemspec

group :development, :test do
  gem 'bundler'
  gem 'hashie'
  gem 'rake'
  gem 'rubocop', '1.25.1'
  gem 'rubocop-ast'
  gem 'rubocop-performance', require: false
  gem 'rubocop-rspec', require: false
end

group :development do
  gem 'appraisal'
  gem 'benchmark-ips'
  gem 'benchmark-memory'
  gem 'guard'
  gem 'guard-rspec'
  gem 'guard-rubocop'
end

group :test do
  gem 'cookiejar'
  gem 'grape-entity', '~> 0.6'
  gem 'maruku'
  gem 'mime-types'
  gem 'rack-jsonp', require: 'rack/jsonp'
  gem 'rack-test', '~> 2.0'
  gem 'rspec', '~> 3.11.0'
  gem 'ruby-grape-danger', '~> 0.2.0', require: false
  gem 'simplecov', '~> 0.21.2'
  gem 'simplecov-lcov', '~> 0.8.0'
  gem 'test-prof', require: false
end

platforms :jruby do
  gem 'racc'
end
