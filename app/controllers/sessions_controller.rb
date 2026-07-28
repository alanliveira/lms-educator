class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  before_action :set_session, only: :destroy
  before_action :find_company, only: [:new]

  layout 'authentication'

  def index
    @sessions = Current.user.sessions.order(created_at: :desc)
  end

  def new; end

  def create
    if user = authenticatable_user
      @session = start_new_session_for(user)
      History.create(user:, action: "Entrou na plataforma")

      redirect_to after_authentication_url, notice: "Login feito com sucesso"
    else
      redirect_to sign_in_path(email_hint: user_params[:email]), alert: "O email e a senha estão incorretos"
    end
  end

  def destroy
    History.create(user: Current.user, action: "Saiu da plataforma")
    @session.destroy unless @session == Current.session
    terminate_session if @session == Current.session
    redirect_to(sessions_path, notice: "That session has been logged out")
  end

  private

  def find_company
    @company = Current.company
  end

  def set_session
    @session = Current.user.sessions.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:email, :password)
  end

  def authentication_params
    user_params.to_h.symbolize_keys.then do |credentials|
      credentials[:email_address] = credentials.delete(:email)
      credentials
    end
  end

  def authenticatable_user
    User.authenticate_by(authentication_params.merge(active: true)).tap do |user|
      return nil if user && Current.company && user.company != Current.company
    end
  end
end
