# frozen_string_literal: true

class WelcomeController < ActionController::Base
  def index
    response = { message: "Welcome to Test Billing App" }

    render json: response, status: :ok
  end
end
