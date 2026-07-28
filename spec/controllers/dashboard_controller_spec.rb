require "rails_helper"

RSpec.describe DashboardController, type: :controller do
  before do
    allow(controller).to receive(:require_authentication)
    allow(controller).to receive(:redirect_to_wrong_domain)
    allow(controller).to receive(:authorize)
    allow(controller).to receive(:default_render)
  end

  around do |example|
    Rails.application.routes.draw do
        get "dashboard/admin" => "dashboard#admin"
        get "dashboard/student" => "dashboard#student"
        get "dashboard/company" => "dashboard#company"
    end

    @routes = Rails.application.routes
    example.run
  ensure
    Rails.application.reload_routes!
  end

  it "loads users for admin dashboards" do
    user = create(:user)
    Current.session = create(:session, user: create(:user, role: :admin))

    get :admin

    expect(controller.instance_variable_get(:@users)).to include(user)
  end

  it "authorizes student dashboards" do
    Current.session = create(:session, user: create(:user, role: :student))

    get :student

    expect(response).to have_http_status(:ok)
  end

  it "loads student users for company dashboards" do
    company = create(:company)
    student = create(:user, company: company, role: :student)
    Current.session = create(:session, user: create(:user, company: company, role: :company))

    get :company

    expect(controller.instance_variable_get(:@users)).to include(student)
  end
end
