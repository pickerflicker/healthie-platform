class Enrollment < ApplicationRecord
  belongs_to :provider
  belongs_to :client

  enum :plan, { basic: "basic", premium: "premium" }, validate: true
  validates :provider_id, uniqueness: { scope: :client_id, message: "is already enrolled" }
end
