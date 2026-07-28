require "rails_helper"

RSpec.describe "Histories", type: :request do
  it "creates a history for the current user" do
    company = create(:company)
    user = create(:user, company: company, role: :student)
    sign_in(user)

    expect do
      post histories_path, params: { history: { action: "Assistiu uma aula" } }
    end.to change(user.histories, :count).by(1)

    expect(response).to have_http_status(:ok)
    expect(user.histories.last.action).to eq("Assistiu uma aula")
  end

  it "returns unprocessable entity when the history is invalid" do
    company = create(:company)
    user = create(:user, company: company, role: :student)
    sign_in(user)

    allow_any_instance_of(History).to receive(:save).and_return(false)

    post histories_path, params: { history: { action: "Falhou" } }

    expect(response).to have_http_status(:unprocessable_content)
  end
end
