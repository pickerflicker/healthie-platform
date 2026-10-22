class AttributeJournalEntriesToProviders < ActiveRecord::Migration[8.1]
  def change
    # Existing non-seed history stays client-only; seed attribution is opt-in.
    add_reference :journal_entries, :provider, null: true, index: false, foreign_key: true
    add_index :journal_entries, [ :provider_id, :client_id, :created_at ], name: "index_journals_on_provider_client_month"
    add_index :journal_entries, [ :provider_id, :created_at, :id ], name: "index_journals_on_provider_feed"
  end
end
