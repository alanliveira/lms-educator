class ApplicationController < ActionController::Base
  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  before_action :set_current_request_details
  before_action :authenticate

  private

  def authenticate
    if session_record = Session.find_by_id(cookies.signed[:session_token])
      Current.session = session_record
    else
      redirect_to sign_in_path
    end
  end

  def set_current_request_details
    Current.user_agent = request.user_agent
    Current.ip_address = request.ip
  end

  def set_redirect_to(user = Current.user)
    if user.has_role? :admin
      dashboard_admin_path
    elsif user.has_role? :company
      dashboard_company_path
    elsif user.has_role? :student
      dashboard_student_path
    end
  end

  def pundit_user
    Current.user
  end

  def user_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore
 
    flash[:alert] = t "#{policy_name}.#{exception.query}", scope: "pundit", default: :default
    redirect_back_or_to(set_redirect_to)
  end
end
