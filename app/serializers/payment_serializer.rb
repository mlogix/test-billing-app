class PaymentSerializer < ActiveModel::Serializer
  attribute :id
  attribute :subscription_id
  attribute :charge_on
  attribute :is_partial
  attribute :initial_payment_id
  attribute :amount
  attribute :gateway_response

  attribute :created_at
end
