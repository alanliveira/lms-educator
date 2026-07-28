module AuthenticationHelpers
  def sign_in(user, password: TestPassword::VALUE)
    post sign_in_path, params: { user: { email: user.email, password: password } }
    expect(response).to redirect_to(root_path)
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :request
end
