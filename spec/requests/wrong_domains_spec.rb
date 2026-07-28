require "rails_helper"

RSpec.describe "Wrong domain", type: :request do
  before do
    host! "www.example.com"
  end

  def create_admin_tenant
    admin_company = create(:company, subdomain: "admin")
    admin_user = create(:user, company: admin_company, role: :admin, email: "admin-owner@example.test")

    [admin_company, admin_user]
  end

  def contact_params
    {
      contact: {
        name: "Visitante",
        phone: "11999999999",
        email: "visitor@example.test",
        whatsapp: "1"
      }
    }
  end

  it "redirects requests without subdomain to the wrong domain page" do
    create_admin_tenant

    get root_path

    expect(response).to redirect_to(wrong_domain_path)
  end

  it "treats admin.localhost as an admin tenant subdomain" do
    create_admin_tenant
    host! "admin.localhost"

    get root_path

    expect(response).to redirect_to(sign_in_path)
  end

  it "renders the contact CTA" do
    create_admin_tenant

    get wrong_domain_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Página errada")
    expect(response.body).to include("contact_name")
    expect(response.body).to include("contact_phone")
    expect(response.body).to include("contact_whatsapp")
    expect(response.body).to include("contact_email")
  end

  it "sends contact requests to admin users from the admin subdomain" do
    _admin_company, admin_user = create_admin_tenant

    expect do
      post wrong_domain_contact_path, params: contact_params
    end.to have_enqueued_mail(WrongDomainMailer, :contact_request)

    mail = WrongDomainMailer.with(contact: contact_params[:contact]).contact_request
    expect(mail.to).to eq([admin_user.email])
  end

  it "renders errors for incomplete contact requests" do
    create_admin_tenant

    expect do
      post wrong_domain_contact_path, params: { contact: { name: "", phone: "", email: "" } }
    end.not_to have_enqueued_mail(WrongDomainMailer, :contact_request)

    expect(response).to have_http_status(:unprocessable_content)
  end
end
