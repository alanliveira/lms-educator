require "rails_helper"

RSpec.describe User, type: :model do
  it "prevents destroying a company owner" do
    company = create(:company)
    owner = create(:user, company: company, role: :company)

    expect(owner.destroy).to be(false)
    expect(owner.errors[:base]).to include("Não é possível excluir um usuário que é proprietário de uma empresa")
  end
end
