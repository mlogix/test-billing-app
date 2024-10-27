# frozen_string_literal: true

module PaymentGateway
  class PaymentGatewayResponse
    include ActiveModel::API

    attr_accessor :status
  end
end
