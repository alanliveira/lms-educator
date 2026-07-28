require "rails_helper"

RSpec.describe "Authentication flows", type: :request do
  describe "sign in" do
    it "creates a tracked session for an active user" do
      company = create(:company, name: "Acme")
      user = create(:user, company: company, role: :student)

      expect do
        expect do
          post sign_in_path, params: { user: { email: user.email, password: TestPassword::VALUE } }
        end.to change { user.sessions.count }.by(1)
      end.to change { user.histories.count }.by(1)

      expect(response).to redirect_to(root_path)
      expect(user.histories.last.action).to eq("Entrou na plataforma")
    end

    it "rejects inactive users" do
      company = create(:company, name: "Inactive Co")
      user = create(:user, company: company, role: :student, active: false)

      expect do
        post sign_in_path, params: { user: { email: user.email, password: TestPassword::VALUE } }
      end.not_to change { user.sessions.count }

      expect(response).to be_redirect
      expect(response.location).to match(%r{/sign_in})
    end
  end

  describe "logout" do
    it "destroys only the current session" do
      company = create(:company, name: "Logout Co")
      user = create(:user, company: company, role: :student)
      other_session = create(:session, user: user)

      sign_in(user)
      current_session = user.sessions.where.not(id: other_session.id).order(:id).last

      expect do
        delete session_path(current_session)
      end.to change { user.sessions.count }.by(-1)

      expect(response).to redirect_to(sessions_path)
      expect(Session.exists?(other_session.id)).to be(true)
      expect(Session.exists?(current_session.id)).to be(false)
    end
  end
end
