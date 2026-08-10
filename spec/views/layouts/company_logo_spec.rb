require "rails_helper"

RSpec.describe "layouts/_company_logo", type: :view do
  it "uses the admin company logo when there is no current company" do
    admin_company = create(:company, subdomain: "admin")
    admin_company.logo.attach(
      io: StringIO.new(File.binread(Rails.root.join("spec/fixtures/files/logo.png"))),
      filename: "logo.png",
      content_type: "image/png"
    )
    admin_company.save!(validate: false)
    Current.reset

    render partial: "layouts/company_logo"

    expect(rendered).to include("alt=\"#{admin_company.fantasy_name}\"")
  end
end
