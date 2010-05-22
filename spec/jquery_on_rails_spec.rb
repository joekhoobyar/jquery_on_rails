require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "JQueryOnRails" do

  it "should not screw up the VERSION" do
    JQueryOnRails.constants.should be_include('VERSION')
    version_file = File.expand_path '../../VERSION', __FILE__
    File.should be_exists(version_file)
    JQueryOnRails::VERSION.should == File.read(version_file).strip
  end

end
