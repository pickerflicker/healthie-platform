class Enrollment < ApplicationRecord
  belongs_to :provider
  belongs_to :client

  enum :plan, { basic: "basic", premium: "premium" }, validate: true
  validates :provider_id, uniqueness: { scope: :client_id, message: "is already enrolled" }

  after_save :invalidate_provider_lists
  after_destroy :invalidate_provider_lists

  private

  def invalidate_provider_lists
    # Capture every affected owner, including earlier saves in this transaction.
    client_ids = [ client_id, *saved_change_to_client_id ].compact.uniq
    Client::ProviderList.invalidate_after_commit { client_ids }
  end
end
