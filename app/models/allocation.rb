# frozen_string_literal: true

# The model store a record of all successful attempt to get paid
#
# @attribute subscription_id [Number] - reference to a subscription
# @attribute payment_id [Number] - In the case when it is partial payment it should be referenced to initial payment
# @attribute amount [Decimal] - payment amount
#
class Allocation < ApplicationRecord
  belongs_to :subscription
  belongs_to :payment
end
