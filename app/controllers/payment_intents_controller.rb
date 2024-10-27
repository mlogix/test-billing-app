# frozen_string_literal: true

class PaymentIntentsController < ApplicationController
  def create
    ::Charge::ChargeService.call(params: payment_intent_params) do |action|
      action.on(:success) do |payment|
        render json: { status: :success, payment: payment }, status: :ok
        return
      end

      action.on(:insufficient_funds) do |payment|
        render json: {
          status: :insufficient_funds,
          payment: payment,
          error: { message: "Insufficient funds" }
        }, status: :ok

        return
      end

      action.on(:failure) do |payment, error|
        render json: { status: :failure, payment: payment, error: error }, status: :conflict
        return
      end
    end
  end

  private

  def payment_intent_params
    params.require(:payment).permit(:subscription_id, :amount)
  end
end
