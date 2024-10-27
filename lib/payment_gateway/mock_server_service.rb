# frozen_string_literal: true

module PaymentGateway
  class MockServerService
    attr_reader :params

    def initialize(params = {})
      @params = params
    end

    def charge(amount)
      # TODO: Implement here the logic to call external server
      # Suppose that by default the service responds with success result
      PaymentGatewayResponse.new(status: StatusCodes::SUCCESS)
    end
  end
end
