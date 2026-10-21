class AddCredentialsToProviders < ActiveRecord::Migration[8.1]
  def change
    add_column :providers, :credentials, :string, array: true, default: [], null: false
    add_check_constraint :providers, <<~SQL.squish, name: "providers_credentials_valid"
      credentials <@ ARRAY['MD', 'RD', 'RDN', 'LD', 'CNS', 'CDCES']::varchar[]
      AND array_position(credentials, NULL) IS NULL
    SQL
  end
end
