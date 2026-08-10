module Companies
  class CreateService
    attr_reader :company

    def initialize(attributes:)
      @company = Company.new(attributes)
    end

    def call
      owner = company.users.first
      owner.active = true

      Company.transaction do
        return false unless company.save

        owner.remove_role(:student)
        owner.add_role(:company)
        company.company_users.find_by!(user: owner).update!(owner: true)
      end

      true
    end
  end
end
