class CompanyPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if user.has_role?(:admin)

      scope.where(id: Current.company&.id)
    end
  end
end
