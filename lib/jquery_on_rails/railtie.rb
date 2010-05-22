require 'jquery_on_rails'
require 'rails'

class JQueryOnRails::Railtie < Rails::Railtie
  
  initializer "jquery_on_rails.action_view_helpers" do
    ActiveSupport.on_load(:action_view) do
      # We want to override Prototype and Scriptaculous - include them first.
			require 'action_view/helpers'
			require 'action_view/helpers/javascript_helper'
			require 'action_view/helpers/prototype_helper'
			require 'action_view/helpers/scriptaculous_helper'
		
      # Include our helpers that override everything.
			require 'jquery_on_rails/helpers/jquery_helper'
			ActionView::Helpers::JavaScriptHelper.send :include, JQueryOnRails::Helpers::JQueryHelper
			ActionView::Helpers.send :include, JQueryOnRails::Helpers::JQueryHelper
			ActionView::Base.send :include, JQueryOnRails::Helpers::JQueryHelper
		
			# Redefine the default sources so that we don't try to include prototype JS files.
			require 'action_view/helpers/asset_tag_helper'
			ActionView::Helpers::AssetTagHelper.class_eval do
			  remove_const :JAVASCRIPT_DEFAULT_SOURCES if const_defined? :JAVASCRIPT_DEFAULT_SOURCES
			  const_set :JAVASCRIPT_DEFAULT_SOURCES, %w/jquery rails/
			  reset_javascript_include_default
			end
		end
  end
end
