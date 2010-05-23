ENV["RAILS_ENV"] = "test"

require 'rubygems'
require 'pp'
begin require 'win32console' and include Win32::Console::ANSI
rescue LoadError
end if RUBY_PLATFORM =~ /msvc|mingw|cygwin|win32/

require File.expand_path("../dummy/config/environment.rb",  __FILE__)
require "rails/test_help"
require "rspec"
#require "rspec/rails"

Rails.backtrace_cleaner.remove_silencers!
ActiveSupport::JSON::Encoding.escape_html_entities_in_json = true

Rspec.configure do |config|
  require 'rspec/expectations'
  config.include Rspec::Matchers
  config.mock_with :rspec
end
