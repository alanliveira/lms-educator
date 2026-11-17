class WrongDomainsController < ApplicationController
  allow_unauthenticated_access

  layout "authentication"

  def show
    redirect_to sign_in_path and return if Company.exists?(subdomain: tenant_subdomain)

    @admin_company = Company.default
    @contact = contact_params.merge(subdomain: tenant_subdomain)
  end

  def create
    @contact = contact_params.merge(subdomain: tenant_subdomain)

    if contact_valid?
      WrongDomainMailer.with(contact: @contact).contact_request.deliver_later
      redirect_to wrong_domain_path, notice: "Recebemos seus dados e entraremos em contato."
    else
      flash.now[:alert] = "Informe nome, telefone e email para solicitar contato."
      render :show, status: :unprocessable_content
    end
  end

  private

  def contact_params
    params.fetch(:contact, {}).permit(:name, :phone, :email, :whatsapp, :subdomain).to_h.symbolize_keys
  end

  def contact_valid?
    @contact.values_at(:name, :phone, :email).all?(&:present?)
  end
end
