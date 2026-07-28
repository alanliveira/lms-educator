require "rails_helper"

RSpec.describe "Initial setup", type: :request do
  def logo_upload
    fixture_file_upload("logo.png", "image/png")
  end

  def setup_params
    {
      company: {
        name: "Primeira Empresa",
        fantasy_name: "Primeira",
        cnpj: "12345678901234",
        address: "Rua Inicial",
        logo: logo_upload
      },
      user: {
        full_name: "Admin Empresa",
        department: "Gestão",
        email: "admin-company@example.test",
        password: TestPassword::VALUE,
        password_confirmation: TestPassword::VALUE
      }
    }
  end

  it "redirects an empty application to the setup screen" do
    get root_path

    expect(response).to redirect_to(new_setup_path)
  end

  it "renders the setup form while the application is empty" do
    get new_setup_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Configuração inicial")
  end

  it "redirects away from setup after the first company exists" do
    create(:company)

    get new_setup_path

    expect(response).to redirect_to(sign_in_path)
  end

  it "creates the first company and owner user" do
    expect do
      post setup_path, params: setup_params
    end.to change(Company, :count).by(1)
      .and change(User, :count).by(1)

    company = Company.find_by!(subdomain: "admin")
    owner = company.owner

    expect(owner.email).to eq("admin-company@example.test")
    expect(owner).to be_active
    expect(owner).to be_verified
    expect(owner).to have_role(:admin)
    expect(owner).not_to have_role(:company)
    expect(response).to redirect_to(sign_in_path)
  end

  it "does not render a subdomain field" do
    get new_setup_path

    expect(response.body).not_to include("company_subdomain")
  end

  it "renders errors for invalid setup params" do
    invalid_params = setup_params
    invalid_params[:company][:name] = ""

    expect do
      post setup_path, params: invalid_params
    end.not_to change(Company, :count)

    expect(response).to have_http_status(:unprocessable_content)
  end
end
