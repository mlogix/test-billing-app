# frozen_string_literal: true

class Subscription < ApplicationRecord
  has_many :payments
end
