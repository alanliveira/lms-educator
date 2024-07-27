class UsersController < ApplicationController
  before_action :find_user, only: [:status]

  def index
    @users = User.all
  end

  def status
    @user.toggle(:active)

    if @user.save
      head :ok
    else
      head :unprocessable_entity
    end
  end

  def new
    @user = User.new
  end

  private

  def find_user
    @user - User.find(params[:id])
  end
end
