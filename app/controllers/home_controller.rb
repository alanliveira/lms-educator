class HomeController < ApplicationController
  def index
    @user = Current.user
    @session = Current.session
  end
end
