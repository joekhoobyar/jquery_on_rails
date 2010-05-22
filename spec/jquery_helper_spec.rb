require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'dummy_controller'

class FakeTemplate
  include ActionView::Helpers

protected
  def form_authenticity_token; end
	def request_forgery_protection_token; end
	def protect_against_forgery?; end
end

describe JQueryOnRails::Helpers::JQueryHelper do
  before(:each) do
    @template = DummyController.new.tap do |c|
	    c.request = ActionDispatch::Request.new Rack::MockRequest.env_for('/dummy')
    end.view_context
  end
  
  describe '#options_for_javascript' do
    before(:each) do
	    @template.singleton_class.instance_eval{ public :options_for_javascript }
	  end

	  it "should handle empty options" do
	    @template.options_for_javascript({}).should == '{}' 
	  end
	  
	  it "should render options deterministically" do
	    @template.options_for_javascript(:b=>1,:c=>3,:a=>2).should == '{a:2, b:1, c:3}'
	  end
  end
  
  describe '#remote_function' do
	  it "should handle the simplest case" do
	    a = Regexp.escape "jQuery.ajax({async:true, data:'authenticity_token=' + encodeURIComponent('"
	    z = Regexp.escape "'), method:'GET', processData:false, url:'/foo'})"
	    @template.remote_function(:url=>'/foo').should =~ /^#{a}.*#{z}$/
	  end
  end
end
