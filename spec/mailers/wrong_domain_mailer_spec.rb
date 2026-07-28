require "rails_helper"

RSpec.describe WrongDomainMailer, type: :mailer do
  it "sends contact requests to admin users in the admin tenant" do
    admin_company = create(:company, subdomain: "admin")
    admin_user = create(:user, company: admin_company, role: :admin, email: "admin-contact@example.test")
    create(:user, role: :admin, email: "global-admin@example.test")

    mail = described_class.with(contact: {
      name: "Visitante",
      phone: "11999999999",
      email: "visitor@example.test",
      whatsapp: "1"
    }).contact_request

    expect(mail.to).to eq([admin_user.email])
    expect(mail.reply_to).to eq(["visitor@example.test"])
    expect(mail.subject).to eq("Contato recebido sem subdomínio")
    expect(mail.body.encoded).to include("Visitante")
  end
end
