require "rails_helper"

RSpec.describe RegistrationsController, type: :controller do
  it "sends email verification for the current registration user" do
    user = create(:user)
    mail = instance_double(ActionMailer::MessageDelivery, deliver_later: true)

    controller.instance_variable_set(:@user, user)
    allow(UserMailer).to receive(:with).with(user: user).and_return(double(email_verification: mail))

    controller.send(:send_email_verification)

    expect(mail).to have_received(:deliver_later)
  end
end
