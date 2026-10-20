class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false, default: ""
      t.string :encrypted_password, null: false, default: ""
      t.string :role, null: false
      t.timestamps
    end
    add_index :users, :email, unique: true
    add_check_constraint :users, "role IN ('provider', 'client')", name: "users_role"
    create_table :providers do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.timestamps
    end
    create_table :clients do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.timestamps
    end
  end
end
