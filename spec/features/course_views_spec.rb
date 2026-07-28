require "rails_helper"

RSpec.describe "Course views", type: :feature do
  it "renders the company sign in screen" do
    company = create(:company, subdomain: "feature-company")

    visit "http://#{company.subdomain}.lvh.me/sign_in"

    expect(page).to have_content(company.fantasy_name)
    expect(page).to have_content("Acesse a nossa plataforma")
    expect(page).to have_button("Fazer o login")
  end

  it "shows viewable courses after signing in" do
    company = create(:company)
    user = create(:user, company: company, role: :student)
    visible_course = create(:course, name: "Capybara Course")
    hidden_course = create(:course, name: "Hidden Capybara Course")
    create(:company_course, company: company, course: visible_course, can_be_viewed: true)
    create(:company_course, company: company, course: hidden_course, can_be_viewed: false)

    visit "http://#{company.subdomain}.lvh.me/sign_in"
    fill_in "user_email", with: user.email
    fill_in "user_password", with: TestPassword::VALUE
    click_button "Fazer o login"

    expect(page).to have_current_path(root_path)
    expect(page).to have_content("Capybara Course")
    expect(page).not_to have_content("Hidden Capybara Course")
  end

  it "shows the company logo on authentication and logged-in screens" do
    company = create(:company, fantasy_name: "Feature Company")
    company.logo.attach(
      io: StringIO.new(File.binread(Rails.root.join("spec/fixtures/files/logo.png"))),
      filename: "logo.png",
      content_type: "image/png"
    )
    company.save!(validate: false)
    expect(company.reload.logo).to be_attached
    user = create(:user, company: company, role: :student)

    visit "http://#{company.subdomain}.lvh.me/sign_in"
    expect(page).to have_css('img[alt="Feature Company"]', count: 1)
    fill_in "user_email", with: user.email
    fill_in "user_password", with: TestPassword::VALUE
    click_button "Fazer o login"

    expect(page).to have_css('img[alt="Feature Company"]', count: 1)
  end
end
