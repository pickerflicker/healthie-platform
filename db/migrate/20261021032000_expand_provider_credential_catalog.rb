class ExpandProviderCredentialCatalog < ActiveRecord::Migration[8.1]
  def up
    remove_check_constraint :providers, name: "providers_credentials_valid"
    add_check_constraint :providers, <<~SQL.squish, name: "providers_credentials_valid"
      credentials <@ ARRAY['MD', 'DO', 'OD', 'DDS', 'DMD', 'DPM', 'DC', 'RN', 'LPN', 'LVN', 'APRN', 'NP', 'DNP', 'BSN', 'MSN', 'CNM', 'CRNA', 'PA-C', 'RD', 'RDN', 'LD', 'LDN', 'CNS', 'CDCES', 'PhD', 'PsyD', 'LCSW', 'LMFT', 'LPC', 'LMHC', 'LPCC', 'MSW', 'LSW', 'LICSW', 'NCC', 'BCBA', 'PT', 'DPT', 'OTD', 'OTR', 'PTA', 'COTA', 'PharmD', 'RPh', 'AuD', 'CCC-A', 'CCC-SLP', 'ND', 'LAc', 'NBC-HWC']::varchar[]
      AND array_position(credentials, NULL) IS NULL
    SQL
  end

  def down
    # Restoring the old constraint could reject or discard newly selected credentials.
    raise ActiveRecord::IrreversibleMigration, "Expanded credentials must be migrated explicitly before restoring the six-value constraint"
  end
end
