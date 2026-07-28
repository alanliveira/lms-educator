require "rails_helper"

RSpec.describe "Application authentication", type: :request do
  it "redirects unauthenticated users to sign in" do
    create(:company)

    get courses_path

    expect(response).to redirect_to(sign_in_path)
  end

  it "redirects unauthenticated users on tenant subdomains to sign in" do
    company = create(:company, subdomain: "tenant-one")
    host! "#{company.subdomain}.lvh.me"

    get courses_path

    expect(response).to redirect_to(sign_in_path)
  end
end
