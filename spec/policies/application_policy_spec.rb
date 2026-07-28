require "rails_helper"

RSpec.describe ApplicationPolicy do
  subject(:policy) { described_class.new(user, record) }

  let(:user) { build_stubbed(:user) }
  let(:record) { Object.new }

  it "denies all default actions" do
    expect(policy.index?).to be(false)
    expect(policy.show?).to be(false)
    expect(policy.create?).to be(false)
    expect(policy.new?).to be(false)
    expect(policy.update?).to be(false)
    expect(policy.edit?).to be(false)
    expect(policy.destroy?).to be(false)
  end

  it "requires subclasses to implement scopes" do
    scope = described_class::Scope.new(user, User.all)

    expect { scope.resolve }.to raise_error(NoMethodError, /must define #resolve/)
  end
end
