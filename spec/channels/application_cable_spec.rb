require "rails_helper"

RSpec.describe ApplicationCable::Channel do
  it "inherits from Action Cable channel base" do
    expect(described_class).to be < ActionCable::Channel::Base
  end
end

RSpec.describe ApplicationCable::Connection do
  it "inherits from Action Cable connection base" do
    expect(described_class).to be < ActionCable::Connection::Base
  end
end
