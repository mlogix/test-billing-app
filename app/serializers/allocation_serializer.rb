class AllocationSerializer < ActiveModel::Serializer
  attribute :id
  attribute :subscription_id
  attribute :payment_id
  attribute :amount
end
