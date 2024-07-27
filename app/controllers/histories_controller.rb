class HistoriesController < ApplicationController
  def create
    @history = History.new
    @history.action = params.dig('history', 'action')
    @history.user = Current.user

    if @history.save
      flash[:notice] = "History successfully created"
      head :ok
    else
      flash[:alert] = "Something went wrong"
      head :unprocessable_entity
    end
  end
end
