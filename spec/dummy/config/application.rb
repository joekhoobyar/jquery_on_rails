require File.expand_path('../boot', __FILE__)

require "active_support/railtie"
require "active_model/railtie"
require "action_dispatch/railtie"
require "action_controller/railtie"
require "action_view/railtie"

require 'jquery_on_rails'

module Dummy
  class Application < Rails::Application
		config.root = File.expand_path '../../', __FILE__
    config.secret_token = 'abcdefghijklmnopqrstuvwxyz0123456789'
		config.session_store :cookie_store, :key => '_dummy_session'
  end
end

