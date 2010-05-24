require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'dummy_controller'

describe JQueryOnRails::Helpers::JQueryUiHelper do
  before(:each) do
    @t = DummyController.new.tap do |c|
      c.request = ActionDispatch::Request.new Rack::MockRequest.env_for('/dummy')
    end.view_context
    @t.extend JQueryOnRails::Helpers::JQueryUiHelper
  end
  describe '#visual_effect' do
    it "calls core jQuery effects primitives" do
      @t.visual_effect(:fade,'blah').should == %(jQuery("#blah").fadeOut();)
      @t.visual_effect(:appear,'blah').should == %(jQuery("#blah").fadeIn();)
    end
    it "calls hide() or show() based on the effect name" do
      @t.visual_effect(:shrink,'blah').should == %(jQuery("#blah").hide('size');)
      @t.visual_effect(:grow,'blah').should == %(jQuery("#blah").show('size');)
      @t.visual_effect(:puff_in,'blah').should == %(jQuery("#blah").show('puff');)
      @t.visual_effect(:puff_out,'blah').should == %(jQuery("#blah").hide('puff');)
    end
    it "calls effect() by default" do
      @t.visual_effect(:puff,'blah').should == %(jQuery("#blah").effect('puff');)
    end
    it "uses default options for :direction" do
      @t.visual_effect(:blind_down,'blah').should ==
        %(jQuery("#blah").show('blind',{direction:'vertical'});)
      @t.visual_effect(:blind_up,'blah').should ==
        %(jQuery("#blah").hide('blind',{direction:'vertical'});)
      @t.visual_effect(:blind_right,'blah').should ==
        %(jQuery("#blah").show('blind',{direction:'horizontal'});)
      @t.visual_effect(:blind_left,'blah').should ==
        %(jQuery("#blah").hide('blind',{direction:'horizontal'});)
      @t.visual_effect(:blind_up,'blah',:direction=>:horizontal).should ==
        %(jQuery("#blah").hide('blind',{direction:'horizontal'});)
      @t.visual_effect(:blind_right,'blah',:direction=>:vertical).should ==
        %(jQuery("#blah").show('blind',{direction:'vertical'});)
    end
    it "uses jQuery UI toggle effects" do
      @t.visual_effect(:toggle_slide,'blah').should == %(jQuery("#blah").toggle('slide',{direction:'vertical'});)
      @t.visual_effect(:toggle_blind,'blah').should == %(jQuery("#blah").toggle('blind',{direction:'vertical'});)
      @t.visual_effect(:toggle_blind,'blah',:direction=>:horizontal).should ==
        %(jQuery("#blah").toggle('blind',{direction:'horizontal'});)
      @t.visual_effect(:toggle_shrink,'blah').should == %(jQuery("#blah").toggle('size');)
      @t.visual_effect(:toggle_grow,'blah').should == %(jQuery("#blah").toggle('size');)
      @t.visual_effect(:toggle_puff,'blah').should == %(jQuery("#blah").toggle('puff');)
    end
    it "implements :toggle_appear with inline JavaScript" do
      body = JQueryOnRails::Helpers::JQueryUiHelper::FX_OPTIONS[:toggleAppear][:mode]
      @t.visual_effect(:toggle_appear,'blah').should == 
        "(function(element,name,options){ #{body} })(jQuery(\"#blah\"),'fade');"
    end
  end
end