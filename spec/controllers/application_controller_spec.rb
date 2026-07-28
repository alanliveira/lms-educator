require "rails_helper"

RSpec.describe ApplicationController, type: :controller do
  it "uses the current user as the pundit user" do
    user = create(:user)
    Current.session = create(:session, user: user)

    expect(controller.send(:pundit_user)).to eq(user)
  end

  it "reports whether a user is authenticated" do
    Current.session = create(:session)

    expect(controller.send(:authenticated?)).to be(true)
  end

  it "redirects unauthorized users with a translated alert" do
    user = create(:user)
    Current.session = create(:session, user: user)
    policy = DashboardPolicy.new(user, :dashboard)
    exception = instance_double(Pundit::NotAuthorizedError, policy: policy, query: :admin?)

    allow(controller).to receive(:redirect_back_or_to)

    controller.send(:user_not_authorized, exception)

    expect(flash[:alert]).to be_present
    expect(controller).to have_received(:redirect_back_or_to).with(root_path)
  end
end
