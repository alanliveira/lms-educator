class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization

  RESERVED_SUBDOMAINS = %w[www].freeze

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  prepend_before_action :redirect_to_wrong_domain
  prepend_before_action :redirect_to_initial_setup
  prepend_before_action :set_current_company_from_subdomain
  before_action :set_current_request_details
  before_action :set_navigation

  private

  def redirect_to_wrong_domain
    return if initial_setup_required?
    return if public_domain_controller?
    return if tenant_subdomain.present? && Company.exists?(subdomain: tenant_subdomain)

    redirect_to wrong_domain_path
  end

  def redirect_to_initial_setup
    return unless initial_setup_required?

    # The initial setup is only served on the `admin` subdomain, so every other
    # host (apex included) is sent there before anything else happens.
    return if controller_path == "setup" && tenant_subdomain == Company::DEFAULT_SUBDOMAIN

    redirect_to new_setup_url(host: admin_host, protocol: request.protocol), allow_other_host: true
  end

  # Host used for the `admin` tenant: `EMAIL_HOST` when configured (same
  # convention as UserMailer#company_host) or the current request host without
  # its subdomain prefix.
  def admin_host
    "#{Company::DEFAULT_SUBDOMAIN}.#{ENV.fetch('EMAIL_HOST', nil).presence || request_base_host}"
  end

  def request_base_host
    host_with_port = request.host_with_port
    return host_with_port if tenant_subdomain.blank?

    host_with_port.delete_prefix("#{tenant_subdomain}.")
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

  def set_navigation
    @page_company = Current.company
    return unless Current.user

    @navigation = {
      company: Current.company,
      session: Current.session,
      show_users: !Current.user.has_role?(:student),
      show_companies: Current.user.has_role?(:admin)
    }
  end

  def set_redirect_to(_user = Current.user)
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
