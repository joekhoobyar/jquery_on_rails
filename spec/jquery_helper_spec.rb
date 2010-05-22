require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'dummy_controller'

describe JQueryOnRails::Helpers::JQueryHelper do
  before(:each) do
    @t = DummyController.new.tap do |c|
	    c.request = ActionDispatch::Request.new Rack::MockRequest.env_for('/dummy')
    end.view_context
  end
  
  it "overrides all instance methods ActionView::Helpers::PrototypeHelper" do
    (ActionView::Helpers::PrototypeHelper.instance_methods -
      JQueryOnRails::Helpers::JQueryHelper.instance_methods).should == []
  end
  it "overrides all instance methods ActionView::Helpers::ScriptaculousHelper" do
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
end
