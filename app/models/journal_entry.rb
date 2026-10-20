class JournalEntry < ApplicationRecord
  belongs_to :client, inverse_of: :journal_entries
  validates :text, presence: true
end
