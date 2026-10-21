class AddCredentialsToProviders < ActiveRecord::Migration[8.1]
  def change
    add_column :providers, :credentials, :string, array: true, default: [], null: false
  end
end
