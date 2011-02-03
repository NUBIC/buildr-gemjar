require File.expand_path("../../spec_helper.rb", __FILE__)

describe BuildrGemjar, "::VERSION" do
  it "exists" do
    lambda { BuildrGemjar::VERSION }.should_not raise_error
  end

  it "has 3 or 4 dot separated parts" do
    BuildrGemjar::VERSION.split('.').size.should be_between(3, 4)
  end
end
