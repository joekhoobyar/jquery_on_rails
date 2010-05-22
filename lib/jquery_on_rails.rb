module JQueryOnRails
  VERSION = File.read(File.expand_path('../../VERSION', __FILE__)).strip
	require 'jquery_on_rails/railtie' if defined? Rails
end
