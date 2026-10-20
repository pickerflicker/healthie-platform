class CreateJournalEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :journal_entries do |t|
      t.references :client, null: false, foreign_key: true, index: false
      t.text :text, null: false
      t.timestamps
    end
    add_index :journal_entries, [ :client_id, :created_at, :id ]
  end
end
