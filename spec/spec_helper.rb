ENV["RAILS_ENV"] = "test"

require 'pp'
require File.expand_path("../dummy/config/environment.rb",  __FILE__)
require "rails/test_help"
require "rspec"
#require "rspec/rails"

Rails.backtrace_cleaner.remove_silencers!

Rspec.configure do |config|
  require 'rspec/expectations'
  config.include Rspec::Matchers
  config.mock_with :rspec
end
