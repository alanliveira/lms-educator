class CoursePolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if user.has_role?(:admin)
      return Current.company.courses if user.has_role?(:company)

      scope.where(
        id: Current.company.company_courses.where(can_be_viewed: true).select(:course_id)
      )
    end
  end
end
