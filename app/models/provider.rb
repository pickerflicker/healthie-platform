class Provider < ApplicationRecord
  has_many :enrollments, dependent: :destroy
  has_many :clients, through: :enrollments
  has_many :journal_entries, through: :clients
  belongs_to :user, inverse_of: :provider
  delegate :name, :email, to: :user
  validates :user_id, uniqueness: true
  validate :matching_role
  validate :immutable_account, on: :update
  before_destroy :retain_account_profile

  private

  def matching_role
    errors.add(:user, "must be a provider without a client profile") unless user&.provider? && user.client.nil?
  end

  def immutable_account
    errors.add(:user, "cannot be reassigned") if will_save_change_to_user_id?
  end

  def retain_account_profile
    throw :abort unless destroyed_by_association
  end
end
