module JQueryOnRails
  module Helpers
    module JQueryUiHelper
      unless const_defined? :RENAME_EFFECTS
        RENAME_EFFECTS = { :appear=>'fadeIn', :fade=>'fadeOut' }
      end
      
      # Basic effects, limited to those supported by core jQuery 1.4
      # Additional effects are supported by jQuery UI.
      def visual_effect(name, element_id = false, js_options = {})
        element = element_id ? ActiveSupport::JSON.encode("##{element_id}") : "element"
        element, before, after = "jQuery(#{element})", '', ''
        
        # [:endcolor, :direction, :startcolor, :scaleMode, :restorecolor]
        if js_options[:startcolor]
          before = ".css('background-color', '#{js_options.delete(:startcolor)}')"
        end
        if js_options[:endcolor]
          after = "css('background-color', '#{js_options.delete(:endcolor)})."
        end
          
        js_options = options_for_javascript js_options
        case name = name.to_sym
        when :toggle_slide
          "#{element}#{before}.#{after}toggle('slide',#{js_options});"
        when :toggle_appear
          "(function(state){ return (function() { state=!state; return #{after}#{element}['fade'+(state?'In':'Out')](#{js_options}); })(); })(#{element}#{before}.css('visiblity')!='hidden');"
        when :toggle_blind
          "#{element}#{before}.#{after}toggle('blind',#{js_options});"
        else
          if name.to_s.start_with('toggle_')
            name, js_options = 'toggle', "'#{name.to_s[7..-1].to_sym}',#{js_options}"
          else
	          name = RENAME_EFFECTS[name] || name.to_s.camelize(false)
	        end
          "#{element}#{before}.#{after}#{name}#(#{js_options});"
        end
      end

    end
  end
end