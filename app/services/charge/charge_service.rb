# frozen_string_literal: true

module Charge
  class ChargeService < BaseService
    def run
      amount = params[:amount].to_f
      subscription_id = params[:subscription_id]

      gateway = PaymentGateway::MockServerService.new
      result = gateway.charge(amount)

      # The payment gateway respond with success status
      if result.status == PaymentGateway::StatusCodes::SUCCESS
        payment = create_succeed_payment(subscription_id, amount, result)

        Rails.logger.info("Made success payment for subscription #{subscription_id} and amount #{amount}")

        return broadcast(:success, payment)
      end

      # Something went wrong, the payment gateway respond with an error
      if result.status == PaymentGateway::StatusCodes::FAILURE
        payment = create_failed_payment(subscription_id, amount, result)

        Rails.logger.info("A payment for subscription #{subscription_id} and amount #{amount} was failed")

        return  broadcast(:failure, payment)
      end

      # The payment gateway respond with insufficient_funds status
      if result.status == PaymentGateway::StatusCodes::INSUFFICIENT_FUNDS
        Rails.logger.info("A payment for subscription #{subscription_id} and amount #{amount} was failed try to re-bill")

        payment = create_insufficient_funds_payment(subscription_id, amount, gateway)
        broadcast(:insufficient_funds, payment)
      end
    end

    private

    def create_succeed_payment(subscription_id, amount, gateway_response)
      # logging success attempt to make a payment
      ActiveRecord::Base.transaction do
        Payment.new(subscription_id: subscription_id).tap do |payment|
          now = Time.now.utc
          payment.amount = amount
          payment.charge_on = now
          payment.charged_at = now
          payment.succeed = true
          payment.partial = false
          payment.gateway_response = gateway_response
          payment.save

          # and logging success money allocation
          allocation = Allocation.new
          allocation.payment = payment
          allocation.subscription = payment.subscription
          allocation.amount = payment.amount
          allocation.save
        end
      end
    end

    def create_failed_payment(subscription_id, amount, gateway_response)
      # Logging an attempt to make a payment.
      Payment.new(subscription_id: subscription_id).tap do |payment|
        payment.amount = amount
        payment.charge_on = Time.now.utc
        payment.succeed = false
        payment.gateway_response = gateway_response
        payment.save
      end
    end

    def create_insufficient_funds_payment(subscription_id, full_amount, gateway)
      attempt_parts = [ 0.75, 0.5, 0.25 ]
      succeed_action = true
      result = nil
      attempt_parts.each_with_index do |part, index|
        new_amount = full_amount * part
        remain_amount = full_amount * (1 - part)

        result = gateway.charge(new_amount)
        # The payment gateway respond with success status
        if result.status == PaymentGateway::StatusCodes::SUCCESS
          payment = create_partial_payment(subscription_id, new_amount, remain_amount, result)
          Rails.logger.info("Made success partial payment for subscription #{subscription_id} and amount #{new_amount}")

          return broadcast(:success, payment)
        end

        # Something went wrong, the payment gateway respond with an error
        if result.status == PaymentGateway::StatusCodes::FAILURE
          payment = create_failed_payment(subscription_id, new_amount, result)
          return  broadcast(:failure, payment)
        end

        # The payment gateway respond with insufficient_funds status
        if result.status == PaymentGateway::StatusCodes::INSUFFICIENT_FUNDS
          # the payment operation failed after 4 attempts
          succeed_action = false if index == attempt_parts.length - 1
        end
      end

      unless succeed_action
        # if tried to charge 4 times schedule a payment in one week for full amount
        create_totally_insufficient_funds_payments(subscription_id, full_amount, result)
      end
    end

    def create_totally_insufficient_funds_payments(subscription_id, amount, gateway_response)
      ActiveRecord::Base.transaction do
        now = Time.now.utc
        # storing an attempt with the failed payment
        payment = Payment.create(
          subscription_id: subscription_id,
          amount: amount,
          charge_on: now,
          partial: false,
          succeed: false,
          gateway_response: gateway_response
        )

        # and reschedule new payment in a week for full amount
        Payment.create(
          subscription_id: subscription_id,
          initial_payment: payment,
          amount: amount,
          charge_on: now + 1.week,
          partial: false
        )

        payment
      end
    end

    def create_partial_payment(subscription_id, amount, remain_amount, gateway_response)
      # create success payment for partial amount
      ActiveRecord::Base.transaction do
        Payment.new(subscription_id: subscription_id).tap do |payment|
          now = Time.now.utc
          payment.amount = amount
          payment.charge_on = now
          payment.charged_at = now
          payment.succeed = true
          payment.partial = true
          payment.gateway_response = gateway_response
          payment.save

          # and logging success money allocation
          allocation = Allocation.new
          allocation.payment = payment
          allocation.subscription = payment.subscription
          allocation.amount = payment.amount
          allocation.save

          # and create scheduled payment for remain amount
          Payment.create(
            subscription_id: subscription_id,
            amount: remain_amount,
            charge_on:  now + 1.week,
            initial_payment: payment,
            partial: true
          )
        end
      end
    end
  end
end
