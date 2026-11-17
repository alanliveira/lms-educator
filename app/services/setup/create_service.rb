module Setup
  class CreateService
    attr_reader :company, :owner

    def initialize(company_attributes:, owner_attributes:)
      @company = Company.new(company_attributes.merge(subdomain: Company::DEFAULT_SUBDOMAIN))
      @owner = User.new(owner_attributes.merge(active: true, verified: true))
    end

    def call
      Company.transaction do
        company.users << owner
        return false unless company.save

        company.company_users.find_by!(user: owner).update!(owner: true)
        owner.remove_role(:student)
        owner.add_role(:admin)
      end

      true
    end
  end
end
