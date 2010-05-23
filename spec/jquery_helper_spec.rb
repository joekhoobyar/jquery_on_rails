require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'dummy_controller'

class Ovechkin < Struct.new(:Ovechkin, :id)
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  def to_key() id ? [id] : nil end
end

describe JQueryOnRails::Helpers::JQueryHelper do
  before(:each) do
    @t = DummyController.new.tap do |c|
	    c.request = ActionDispatch::Request.new Rack::MockRequest.env_for('/dummy')
    end.view_context
  end

	def create_generator
	  block = Proc.new{|*args| yield *args if block_given?}
	  @t.class::JavaScriptGenerator.new @t, &block
	end
  
  it "is automatically mixed into the template class" do
    @t.class.included_modules.should be_include(JQueryOnRails::Helpers::JQueryHelper)
  end
  it "overrides all instance methods from ActionView::Helpers::PrototypeHelper" do
    (ActionView::Helpers::PrototypeHelper.instance_methods -
      JQueryOnRails::Helpers::JQueryHelper.instance_methods).should == []
  end
  it "overrides all instance methods from ActionView::Helpers::ScriptaculousHelper" do
    return pending("not yet implemented")
    (ActionView::Helpers::ScriptaculousHelper.instance_methods -
      JQueryOnRails::Helpers::JQueryHelper.instance_methods).should == []
  end
  
  describe '#options_for_javascript' do
    before(:each) do
	    @t.singleton_class.instance_eval{ public :options_for_javascript }
	  end

	  it "handles empty options" do
	    @t.options_for_javascript({}).should == '{}' 
	  end
	  it "orders options deterministically" do
	    @t.options_for_javascript(:b=>1,:c=>3,:a=>2).should == '{a:2, b:1, c:3}'
	  end
  end
  
  describe '#remote_function' do
	  it "calls jQuery.ajax" do
	    # jQuery.ajax({async:true,   ...   method:'GET', processData:false,  ...   })
	    @t.remote_function(:url=>'/foo').should =~ /jQuery\.ajax\(.*.*\)/
	  end
	  it "is asynchronous by default" do
	    @t.remote_function(:url=>'/foo').should =~ /async: *true/
	  end
	  it "can be explicitly synchronous" do
	    @t.remote_function(:url=>'/foo', :type=>:synchronous).should =~ /async: *false/
	  end
	  
	  describe 'request forgery protection' do
	    before(:each) do
	      @regex = /data: *'#{@t.request_forgery_protection_token}=' *\+ *encodeURIComponent/
	    end

		  it "is included by default" do
		    @t.remote_function(:url=>'/foo').should =~ @regex
		  end
		  it "can be explicitly omitted" do
		    @t.remote_function(:url=>'/foo', :protect_against_forgery=>false).should_not =~ @regex
	    end
		  it "is omitted when :form is given" do
		    @t.remote_function(:url=>'/foo', :form=>true).should_not =~ @regex
	    end
	  end
	  
	  describe ':url' do
		  it "accepts a string" do
		    @t.remote_function(:url=>'/foo').should =~ /url: *'\/foo'/
		  end
		  it "accepts a hash" do
		    @t.remote_function(:url=>{:controller=>'dummy', :action=>'index'}).should =~ /url: *'\/dummy'/
		  end
	  end
	  
	  describe ':method' do
		  it "defaults to GET" do
		    @t.remote_function(:url=>'/foo').should =~ /method: *'GET'/
		  end
		  it "is capitalized" do
		    @t.remote_function(:url=>'/foo', :method=>:post).should =~ /method: *'POST'/
		  end
	  end
  end
  
  describe '#visual_effect' do
	  it "renames effects" do
	    @t.visual_effect(:fade,'blah').should == %(jQuery("#blah").fadeOut();)
	    @t.visual_effect(:appear,'blah').should == %(jQuery("#blah").fadeIn();)
	  end
	  it "renames toggle effects" do
	    @t.visual_effect(:toggle_slide,'blah').should == %(jQuery("#blah").slideToggle();)
	  end
	  it "rewrites :toggle_appear" do
	    @t.visual_effect(:toggle_appear,'blah').should == 
	      "(function(state){ return (function() { state=!state; return jQuery(\"#blah\")['fade'+(state?'In':'Out')](); })(); })(jQuery(\"#blah\").css('visiblity')!='hidden');"
	  end
  end

  describe '#update_page' do
    it 'matches output from #create_generator' do
      @block = proc{|page| page.replace_html 'foo', 'bar'}
      @t.update_page(&@block).should == create_generator(&@block).to_s
    end
  end
  
  describe '#update_page_tag' do
    before(:each) do
      @block = proc{|page| page.replace_html 'foo', 'bar'}
    end
    it 'matches output from #create_generator wrapped in a script tag' do
      @t.update_page_tag(&@block).should == @t.javascript_tag(create_generator(&@block).to_s)
    end
    it 'outputs html attributes' do
      @t.update_page_tag(:defer=>true, &@block).should == @t.javascript_tag(create_generator(&@block).to_s, :defer=>true)
    end
  end
  
	describe 'JavaScriptGenerator' do
	  before(:each) do
	    @g = create_generator
	  end
	  it "replaces the PrototypeHelper's generator" do
	      @t.class::JavaScriptGenerator.should == JQueryOnRails::Helpers::JQueryHelper::JavaScriptGenerator
	      JQueryOnRails::Helpers::JQueryHelper::JavaScriptGenerator.should === @g
	  end
	  it "#insert_html" do
	    @g.insert_html(:top, 'element', '<p>This is a test</p>').should ==
	      'jQuery("#element").prepend("\\u003Cp\\u003EThis is a test\\u003C/p\\u003E");'
	    @g.insert_html(:bottom, 'element', '<p>This is a test</p>').should ==
	      'jQuery("#element").append("\\u003Cp\\u003EThis is a test\\u003C/p\\u003E");'
	    @g.insert_html(:before, 'element', '<p>This is a test</p>').should ==
	      'jQuery("#element").before("\\u003Cp\\u003EThis is a test\\u003C/p\\u003E");'
	    @g.insert_html(:after, 'element', '<p>This is a test</p>').should ==
	      'jQuery("#element").after("\\u003Cp\\u003EThis is a test\\u003C/p\\u003E");'
	  end
	  it "#replace_html" do
      @g.replace_html('element', '<p>This is a test</p>').should ==
		    'jQuery("#element").html("\\u003Cp\\u003EThis is a test\\u003C/p\\u003E");'
	  end
	  it "#replace" do
      @g.replace('element', '<div id="element"><p>This is a test</p></div>').should ==
		    'jQuery("#element").replaceWith("\\u003Cdiv id=\"element\"\\u003E\\u003Cp\\u003EThis is a test\\u003C/p\\u003E\\u003C/div\\u003E");'
	  end
	  it "#remove" do
      @g.remove('foo').should == 'jQuery("#foo").remove();'
      @g.remove('foo', 'bar', 'baz').should == 'jQuery("#foo, #bar, #baz").remove();'
	  end
	  it "#show" do
	    @g.show('foo').should == 'jQuery("#foo").show();'
      @g.show('foo', 'bar', 'baz').should == 'jQuery("#foo, #bar, #baz").show();'
	  end
	  it "#hide" do
	    @g.hide('foo').should == 'jQuery("#foo").hide();'
      @g.hide('foo', 'bar', 'baz').should == 'jQuery("#foo, #bar, #baz").hide();'
	  end
	  it "#toggle" do
	    @g.toggle('foo').should == 'jQuery("#foo").toggle();'
      @g.toggle('foo', 'bar', 'baz').should == 'jQuery("#foo, #bar, #baz").toggle();'
	  end
	  it "#alert" do
			@g.alert('hello').should == 'alert("hello");'
	  end
	  it "#redirect_to" do
			@g.redirect_to(:controller=>'dummy', :action=>'index').should ==
			  'window.location.href = "/dummy";'
			@g.redirect_to("http://www.example.com/welcome?a=b&c=d").should == 
			  'window.location.href = "http://www.example.com/welcome?a=b&c=d";'
	  end
	  it "#reload" do
			@g.reload.should == 'window.location.reload();'
	  end
	  it "#delay" do
	    @g.delay(20){@g.hide('foo')}
	    @g.to_s.should == "setTimeout(function(){\n;\njQuery(\"#foo\").hide();\n}, 20000);"
	  end
	  it "#to_s" do
	    @g.insert_html(:top, 'element', '<p>This is a test</p>')
	    @g.insert_html(:bottom, 'element', '<p>This is a test</p>')
	    @g.remove('foo', 'bar')
	    @g.replace_html('baz', '<p>This is a test</p>')
	
	    @g.to_s.should == <<-EOS.chomp
jQuery("#element").prepend("\\u003Cp\\u003EThis is a test\\u003C/p\\u003E");
jQuery("#element").append("\\u003Cp\\u003EThis is a test\\u003C/p\\u003E");
jQuery("#foo, #bar").remove();
jQuery("#baz").html("\\u003Cp\\u003EThis is a test\\u003C/p\\u003E");
EOS
	  end
	  it "#literal" do
	    ActiveSupport::JSON.encode(@g.literal("function() {}")).should == "function() {}"
	    @g.to_s.should == ""
	  end
	  it "proxies to class methods" do
	    @g.form.focus('my_field')
	    @g.to_s.should == "Form.focus(\"my_field\");"
	  end
	  it "proxies to class methods with blocks" do
	    @g.my_object.my_method do |p|
	      p[:one].show
	      p[:two].hide
	    end
	    @g.to_s.should == "MyObject.myMethod(function() { jQuery(\"#one\").show();\njQuery(\"#two\").hide(); });"
	  end
	  it "calls with or without blocks" do
	    @g.call(:before)
	    @g.call(:my_method) do |p|
	      p[:one].show
	      p[:two].hide
	    end
	    @g.call(:in_between)
	    @g.call(:my_method_with_arguments, true, "hello") do |p|
	      p[:three].toggle
	    end
	    @g.to_s.should == "before();\nmy_method(function() { jQuery(\"#one\").show();\njQuery(\"#two\").hide(); });\nin_between();\nmy_method_with_arguments(true, \"hello\", function() { jQuery(\"#three\").toggle(); });"
	  end
	  it '#visual_effect matches helper method output' do
	    @g.visual_effect(:toggle_slide,'blah')
	    @g.to_s.should == @t.visual_effect(:toggle_slide,'blah')
	  end
	
	  describe "element proxy compatibility" do
	    before(:each) do
	      @g.extend @g.class::CompatibilityMethods
	    end
	    it "gets properties" do
	      @g['hello']['style']
	      @g.to_s.should == 'jQuery("#hello")[0].style;'
	    end
	    it "gets nested properties" do
	      @g['hello']['style']['color']
	      @g.to_s.should == 'jQuery("#hello")[0].style.color;'
	    end
	    it "sets properties" do
	      @g['hello'].width = 400;
	      @g.to_s.should == 'jQuery("#hello")[0].width = 400;'
	    end
	    it "sets nested properties" do
	      @g['hello']['style']['color'] = 'red';
	      @g.to_s.should == 'jQuery("#hello")[0].style.color = "red";'
	    end
	  end
	  describe "element proxy" do
      it "refers by element ID" do
			  @g['hello']
			  @g.to_s.should == 'jQuery("#hello")'
      end
      it "refers by element ID, using ActiveModel::Naming" do
			  @g[Ovechkin.new]
			  @g.to_s.should == 'jQuery("#new_ovechkin")'
      end
      it "refers indirectly" do
        @g['hello'].hide('first').show
        @g.to_s.should == 'jQuery("#hello").hide("first").show();'
      end
      it "calls methods" do
        @g['hello'].hide
        @g.to_s.should == 'jQuery("#hello").hide();'
      end
      it "gets properties" do
        @g['hello'][0]['style']
        @g.to_s.should == 'jQuery("#hello")[0].style;'
      end
      it "gets nested properties" do
        @g['hello'][0]['style']['color']
        @g.to_s.should == 'jQuery("#hello")[0].style.color;'
      end
      it "sets properties" do
        @g['hello'][0].width = 400;
        @g.to_s.should == 'jQuery("#hello")[0].width = 400;'
      end
      it "sets nested properties" do
        @g['hello'][0]['style']['color'] = 'red';
        @g.to_s.should == 'jQuery("#hello")[0].style.color = "red";'
      end
	  end
	  
  end
end
