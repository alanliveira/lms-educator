class HistoriesController < ApplicationController
  def create
    @history = History.new
    @history.action = params.dig('history', 'action')
    @history.user = Current.user

    if @history.save
      head :ok
    else
      head :unprocessable_entity
    end
  end
end
