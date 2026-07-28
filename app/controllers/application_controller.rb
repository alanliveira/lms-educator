class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization

  RESERVED_SUBDOMAINS = %w[www].freeze

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  prepend_before_action :redirect_to_wrong_domain
  prepend_before_action :redirect_to_initial_setup
  prepend_before_action :set_current_company_from_subdomain
  before_action :set_current_request_details

  private

  def redirect_to_wrong_domain
    return if initial_setup_required?
    return if tenant_subdomain.present? && !RESERVED_SUBDOMAINS.include?(tenant_subdomain)
    return if public_domain_controller?

    redirect_to wrong_domain_path
  end

  def redirect_to_initial_setup
    redirect_to new_setup_path if initial_setup_required? && controller_path != "setup"
  end

  def initial_setup_required?
    Company.none? && User.none?
  end

  def set_current_company_from_subdomain
    Current.company = nil
    return if tenant_subdomain.blank? || RESERVED_SUBDOMAINS.include?(tenant_subdomain)

    Current.company = Company.find_by(subdomain: tenant_subdomain)
  end

  def tenant_subdomain
    localhost_subdomain || request.subdomains.first.to_s.downcase
  end

  def localhost_subdomain
    host = request.host.to_s.downcase
    return unless host.end_with?(".localhost")

    host.delete_suffix(".localhost").split(".").last
  end

  def public_domain_controller?
    controller_path.in?(%w[wrong_domains setup rails/health certificate_validations]) || controller_path.start_with?("rswag/")
  end

  def set_current_request_details
    Current.user_agent = request.user_agent
    Current.ip_address = request.ip
  end

  def set_redirect_to(user = Current.user)
    root_path
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
