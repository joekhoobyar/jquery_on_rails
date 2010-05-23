require 'active_support'

module JQueryOnRails
  VERSION = File.read(File.expand_path('../../VERSION', __FILE__)).strip
  
  module Helpers
    extend ActiveSupport::Autoload

    autoload :JQueryHelper, 'jquery_on_rails/helpers/jquery_helper'
    autoload :JQueryUiHelper, 'jquery_on_rails/helpers/jquery_ui_helper'
  end

	require 'jquery_on_rails/railtie' if defined? Rails
end
