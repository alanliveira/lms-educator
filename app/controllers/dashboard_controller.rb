class DashboardController < ApplicationController
  def admin
    authorize :dashboard
    @users = User.all
  end

  def student
    authorize :dashboard
  end

  def company
    authorize :dashboard
    @users = User.with_role(:student)
  end
end
