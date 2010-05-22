# Copyright (c) 2010 Joe Khoobyar
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
require 'set'

module JQueryOnRails
  module Helpers

    module JQueryHelper
      unless const_defined? :CALLBACKS
        CALLBACKS = { :beforeSend=>'request', :complete=>'request,status',
                      :error=>'request,status,exception', :success=>'data,status,request' }
        INSERT_POSITIONS = { :before=>'before', :after=>'after', :top=>'prepend', :bottom=>'append' }
        AJAX_OPTIONS = Set.new([:cache, :contentType, :data, :dataType, :dataFilter, :global, :ifModified,
                                :jsonp, :jsonpCallback, :password, :processData, :scriptCharset,
                                :timeout, :traditional, :type, :username, :xhr])
        CONFIRM_FUNCTION = 'confirm'.freeze
      end
      
      # Returns the JavaScript needed for a remote function.
      # Takes the same arguments as link_to_remote.
      #
      # Example:
      #   # Generates: <select id="options" onchange="$.ajax({method : 'GET',
      #   # url : '/testing/update_options', async:true, evalScripts:true,
      #   # complete : function(data,status,request){$('#options').html(request.responseText)}})">
      #   <select id="options" onchange="<%= remote_function(:update => "options",
      #       :url => { :action => :update_options }) %>">
      #     <option value="0">Hello</option>
      #     <option value="1">World</option>
      #   </select>
      def remote_function(options)
        function = "jQuery.ajax(#{options_for_ajax(options)})"
        function = "#{options[:before]}; #{function}" if options[:before]
        function = "#{function}; #{options[:after]}"  if options[:after]
        function = "if (#{options[:condition]}) { #{function}; }" if options[:condition]
        function = "if (#{confirm_for_javascript(options[:confirm])}) { #{function}; }" if options[:confirm]
        function
      end
    
      # Mostly copied from PrototypeHelper
      class JavaScriptGenerator #:nodoc:
        def initialize(context, &block) #:nodoc:
          @context, @lines = context, []
          include_helpers_from_context
          @context.with_output_buffer(@lines) do
            @context.instance_exec(self, &block)
          end
        end
    
	    private
	      def include_helpers_from_context
	        extend @context.helpers if @context.respond_to?(:helpers)
	        extend GeneratorMethods
	      end
    
        module GeneratorMethods
          def to_s #:nodoc:
            returning javascript = @lines * $/ do
              if ActionView::Base.debug_rjs
                source = javascript.dup
                javascript.replace "try {\n#{source}\n} catch (e) "
                javascript << "{ alert('RJS error:\\n\\n' + e.toString()); alert('#{source.gsub('\\','\0\0').gsub(/\r\n|\n|\r/, "\\n").gsub(/["']/) { |m| "\\#{m}" }}'); throw e }"
              end
            end
          end
    
          def [](id)
            case id
              when String, Symbol, NilClass
                JavaScriptElementProxy.new(self, id)
              else
                JavaScriptElementProxy.new(self, ActionController::RecordIdentifier.dom_id(id))
            end
          end
    
          def literal(code)
            ::ActiveSupport::JSON::Variable.new(code.to_s)
          end
    
          def select(pattern)
            JavaScriptElementCollectionProxy.new(self, pattern)
          end
    
          def insert_html(position, id, *options_for_render)
            content = javascript_object_for(render(*options_for_render))
	          position = INSERTION_POSITIONS[position.to_sym] || position.to_s.downcase
            record "jQuery('##{id}').#{position}(#{content});"
          end
    
          def replace_html(id, *options_for_render)
            content = javascript_object_for(render(*options_for_render))
            record "jQuery('##{id}').html(#{content});"
          end
    
          def replace(id, *options_for_render)
            content = javascript_object_for(render(*options_for_render))
            record "jQuery('##{id}').replaceWith(#{content});"
          end
    
          def remove(*ids)
            loop_on_multiple_ids 'remove', ids
          end
    
          def show(*ids)
            loop_on_multiple_ids 'show', ids
          end
    
          def hide(*ids)
            loop_on_multiple_ids 'hide', ids
          end
    
          def toggle(*ids)
            loop_on_multiple_ids 'toggle', ids
          end
    
          def alert(message)
            call 'alert', message
          end
    
          def redirect_to(location)
            url = location.is_a?(String) ? location : @context.url_for(location)
            record "window.location.href = #{url.inspect}"
          end
    
          def reload
            record 'window.location.reload()'
          end
    
          def call(function, *arguments, &block)
            record "#{function}(#{arguments_for_call(arguments, block)})"
          end
    
          def assign(variable, value)
            record "#{variable} = #{javascript_object_for(value)}"
          end
    
          def <<(javascript)
            @lines << javascript
          end
    
          def delay(seconds = 1)
            record "setTimeout(function() {\n\n"
            yield
            record "}, #{(seconds * 1000).to_i})"
          end
    
          private
            def loop_on_multiple_ids(method, ids)
	            record "jQuery('##{ids.join(', #')}').#{method} ();"
            end
    
            def page
              self
            end
    
            def record(line)
              returning line = "#{line.to_s.chomp.gsub(/\;\z/, '')};" do
                self << line
              end
            end
    
            def render(*options)
              with_formats(:html) do
                case option = options.first
                when Hash
                  @context.render(*options)
                else
                  option.to_s
                end
              end
            end
    
            def with_formats(*args)
              @context ? @context.update_details(:formats => args) { yield } : yield
            end
    
            def javascript_object_for(object)
              ::ActiveSupport::JSON.encode(object)
            end
    
            def arguments_for_call(arguments, block = nil)
              arguments << block_to_function(block) if block
              arguments.map { |argument| javascript_object_for(argument) }.join ', '
            end
    
            def block_to_function(block)
              generator = self.class.new(@context, &block)
              literal("function() { #{generator.to_s} }")
            end
    
            def method_missing(method, *arguments)
              JavaScriptProxy.new(self, method.to_s.camelize)
            end
        end
      end
    
      def update_page(&block)
        JavaScriptGenerator.new(view_context, &block).to_s.html_safe
      end
    
      def update_page_tag(html_options = {}, &block)
        javascript_tag update_page(&block), html_options
      end
    
	  protected
	  
      # Generates a JavaScript confirm() method call.
	    def confirm_for_javascript(confirm)
	      case confirm
	      when Hash
	        confirm = options_for_javascript(confirm)
	      when Array
	        confirm = "[#{confirm.join(',')}]"
	      else
	        confirm = "'#{escape_javascript(confirm)}'"
	      end
        "#{CONFIRM_FUNCTION}(#{confirm})"
	    end

		  def options_for_javascript(options)
	      if options.empty? then '{}' else
	        "{#{options.keys.map { |k| "#{k}:#{options[k]}" }.sort.join(', ')}}"
	      end
	    end
	    
	    def options_for_ajax(options)
	      js_options = { 'async'  => (options[:type] != :synchronous),
									     'method' => method_option_to_s(options[:method] || :GET) }
									       
	      html_js = 'request.responseText'
	      html_js << ".replace(/<script(.|\\s)*?\\/script>/gi, '')" if options[:script].nil? or options[:script]
	      if (update_js = options[:position]) !~ /^[a-zA-Z0-9_]+/
	        update_js = 'html'
	      elsif INSERT_POSITIONS.include?(update_js.to_sym)
	        update_js = INSERT_POSITIONS[update_js]
	      end
        url_options = url_for url_options.merge(:escape => false) if (url_options = options[:url]).is_a?(Hash)
        url_options = "'#{escape_javascript url_options}'" unless url_options.is_a?(ActiveSupport::JSON::Variable)
        js_options['url'] = url_options

	      if options[:form]
	        js_options['data'] = "jQuery(this).closest('form').serialize()"
	      elsif options[:submit]
	        js_options['data'] = "jQuery('##{options[:submit]}').serialize()"
	      elsif options[:with]
	        js_options['data'] = options[:with]
	      end
	      
	      if Hash === (update = options[:update])
	        js_options['error'] = "jQuery('##{update[:failure]}').#{update_js}(#{html_js});" if update[:failure]
	        js_options['success'] = "jQuery('##{update[:success]}').#{update_js}(#{html_js});" if update[:success]
        elsif update
          js_options['complete'] = "if(status==='success' || status==='notmodified'){" +
													            "jQuery('##{update}').#{update_js}(#{html_js});" +
													         "}"  
        end
	    
	      if !(FalseClass === options[:protect_against_forgery?]) or
		        protect_against_forgery? or !options[:form] or !options[:submit]
		    then
	        if js_options['data']
	          js_options['data'] << " + '&"
	        else
	          js_options['data'] = "'"
	        end
	        js_options['data'] << "#{request_forgery_protection_token}=' + encodeURIComponent('#{escape_javascript form_authenticity_token}')"
	      end
	      
        js_options['processData'] = false if js_options.include? 'data'
        AJAX_OPTIONS.each do |sym|
          name = sym.to_s
	        js_options[name] = options[sym] if options.include?(sym) and ! js_options.include?(name)
        end
	      build_callbacks options, js_options

        options_for_javascript(js_options)
	    end
	    
	    def method_option_to_s(method)
	      (method.is_a?(String) and !method.index("'").nil?) ? method : "'#{method.to_s.upcase}'"
	    end
	    
      def build_callbacks(options,js_options={})
        CALLBACKS.each do |sym,signature|
          name = sym.to_s
          code = options.include?(sym) ? "#{js_options[name]}#{options[sym]}" : js_options[name];
	        js_options[name] = "function(#{signature}){#{code}}" unless code.blank? and ! js_options.include?(name)
        end
	      js_options
	    end

    end
  end
end