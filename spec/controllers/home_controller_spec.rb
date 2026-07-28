require "rails_helper"

RSpec.describe HomeController, type: :controller do
  around do |example|
    Rails.application.routes.draw do
      get "home" => "home#index"
    end

    @routes = Rails.application.routes
    example.run
  ensure
    Rails.application.reload_routes!
  end

  it "renders the home index" do
    allow(controller).to receive(:require_authentication)
    allow(controller).to receive(:redirect_to_initial_setup)

    get :index

    expect(response).to have_http_status(:ok)
  end
end
