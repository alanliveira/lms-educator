require "rails_helper"

RSpec.describe "Sessions", type: :request do
  it "renders the sign in form with company context" do
    company = create(:company, subdomain: "login-company")
    host! "#{company.subdomain}.lvh.me"

    get sign_in_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(company.fantasy_name)
  end

  it "lists sessions for the current user" do
    company = create(:company)
    user = create(:user, company: company)
    sign_in(user)

    get sessions_path

    expect(response).to have_http_status(:ok)
  end

  it "creates a native session cookie for valid credentials" do
    user = create(:user)

    expect do
      post sign_in_path, params: { user: { email: user.email, password: TestPassword::VALUE } }
    end.to change(Session, :count).by(1)

    expect(response).to redirect_to(courses_path)
    expect(response.cookies["session_id"]).to be_present
    expect(Session.last).to have_attributes(user: user)
  end

  it "rejects inactive users" do
    user = create(:user, active: false)

    expect do
      post sign_in_path, params: { user: { email: user.email, password: TestPassword::VALUE } }
    end.not_to change(Session, :count)

    expect(response).to redirect_to(sign_in_path(email_hint: user.email))
    expect(response.cookies["session_id"]).to be_nil
  end

  it "destroys only the selected non-current session" do
    user = create(:user)
    sign_in(user)
    current_session = Session.last
    other_session = create(:session, user: user)

    delete session_path(other_session)

    expect(response).to redirect_to(sessions_path)
    expect(Session.exists?(current_session.id)).to be(true)
    expect(Session.exists?(other_session.id)).to be(false)

    get sessions_path
    expect(response).to have_http_status(:ok)
  end

  it "destroys the current session and clears the cookie" do
    user = create(:user)
    sign_in(user)
    current_session = Session.last

    delete session_path(current_session)

    expect(response).to redirect_to(sessions_path)
    expect(Session.exists?(current_session.id)).to be(false)
    expect(response.cookies["session_id"]).to be_nil
  end

  it "always redirects to courses after authentication" do
    company = create(:company, subdomain: "courses-after-login")
    user = create(:user, company: company)
    host! "#{company.subdomain}.lvh.me"

    get sessions_path
    post sign_in_path, params: { user: { email: user.email, password: TestPassword::VALUE } }

    expect(response).to redirect_to(courses_path)
  end
end
