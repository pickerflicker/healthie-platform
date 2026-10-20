class Client < ApplicationRecord
  has_many :enrollments, dependent: :destroy
  has_many :providers, through: :enrollments
  has_many :journal_entries, dependent: :destroy
  belongs_to :user, inverse_of: :client
  delegate :name, :email, to: :user
  validates :user_id, uniqueness: true
  validate :matching_role
  validate :immutable_account, on: :update
  before_destroy :retain_account_profile

  def self.provider_list_cache_key(client_id)
    "clients/#{client_id}/provider-list/v2"
  end

  def provider_list
    Rails.cache.fetch(self.class.provider_list_cache_key(id), expires_in: 1.minute) { query_provider_list }
  end

  private

  def query_provider_list
    enrollments.order(created_at: :desc, id: :desc).preload(provider: :user).map do |enrollment|
      { enrollment_id: enrollment.id, provider_id: enrollment.provider_id,
        name: enrollment.provider.name, plan: enrollment.plan }
    end
  end

  def matching_role
    errors.add(:user, "must be a client without a provider profile") unless user&.client? && user.provider.nil?
  end

  def immutable_account
    errors.add(:user, "cannot be reassigned") if will_save_change_to_user_id?
  end

  def retain_account_profile
    throw :abort unless destroyed_by_association
  end
end
