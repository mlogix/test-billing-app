# frozen_string_literal: true

# The purpose of the model is to store data about each payment attempt.
#
# @attribute subscription_id [Number] - reference to a subscription
# @attribute charge_on [Time] - scheduled date of payment
# @attribute partial [Boolean] - partial payment
# @attribute initial_payment_id [Number] - In the case when it is partial payment it should be referenced to initial payment
# @attribute amount [Decimal] - payment amount
# @attribute charged_at [Time] - payment processing time
# @attribute succeed [Boolean] - is the result succeed
# @attribute gateway_response [JSON] - any response from payment gateway
#
class Payment < ApplicationRecord
  belongs_to :subscription

  belongs_to :initial_payment,
             class_name: "Payment",
             foreign_key: "initial_payment_id",
             optional: true
end
