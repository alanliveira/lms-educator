require "swagger_helper"

RSpec.describe "Health", type: :request do
  path "/up" do
    get "checks application health" do
      tags "Health"
      produces "text/html"

      response "200", "application is healthy" do
        run_test!
      end
    end
  end
end
