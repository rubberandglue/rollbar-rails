# require "bundler/setup"
# require "rollbar/rails"

begin
  require 'simplecov'
  require 'codeclimate-test-reporter'

  SimpleCov.start do
    add_filter '/spec/'

    formatter SimpleCov::Formatter::MultiFormatter.new(
                [
                  SimpleCov::Formatter::HTMLFormatter,
                  CodeClimate::TestReporter::Formatter
                ]
              )
  end
rescue LoadError
end

require 'rubygems'

ENV['RAILS_ENV'] = ENV['RACK_ENV'] = 'test'
require File.expand_path('../dummyapp/config/environment', __FILE__)
require 'rspec/rails'

require 'database_cleaner'

namespace :dummy do
  load 'spec/dummyapp/Rakefile'
end

if Gem::Version.new(Rails.version) < Gem::Version.new('5.0')
  Rake::Task['dummy:db:setup'].invoke
else
  Rake::Task['dummy:db:test:prepare'].invoke
end

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.extend(Helpers)
  config.include(NotifierHelpers)
  config.include(FixtureHelpers)
  config.include(EncodingHelpers)

  config.color                      = true
  config.use_transactional_fixtures = true
  config.formatter                  = 'documentation'

  config.order = 'random'
  config.expect_with(:rspec) do |c|
    c.syntax = [:should, :expect]
  end

  config.mock_with :rspec do |mocks|
    mocks.syntax = [:should, :expect]
  end

  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
    DatabaseCleaner.clean
    Rollbar.clear_notifier!

    stub_request(:any, /api.rollbar.com/).to_rack(RollbarAPI.new) if defined?(WebMock)
  end

  config.after do
    DatabaseCleaner.clean
  end

  config.infer_spec_type_from_file_location! if config.respond_to?(:infer_spec_type_from_file_location!)
  config.backtrace_exclusion_patterns = [/gems\/rspec-.*/]
end
