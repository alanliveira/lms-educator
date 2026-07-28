require "rails_helper"

RSpec.describe ApplicationJob, type: :job do
  it "inherits from Active Job base" do
    expect(described_class).to be < ActiveJob::Base
  end
end
