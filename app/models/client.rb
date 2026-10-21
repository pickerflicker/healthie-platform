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

  def provider_list
    ProviderList.new(self).fetch
  end

  private

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
