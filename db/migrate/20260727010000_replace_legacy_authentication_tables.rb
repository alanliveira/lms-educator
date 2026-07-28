class ReplaceLegacyAuthenticationTables < ActiveRecord::Migration[8.0]
  def up
    drop_table :sessions, if_exists: true

    if column_exists?(:users, :email) && !column_exists?(:users, :email_address)
      remove_index :users, :email if index_exists?(:users, :email)
      rename_column :users, :email, :email_address
    end

    add_index :users, :email_address, unique: true unless index_exists?(:users, :email_address)

    create_table :sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end
  end

  def down
    drop_table :sessions, if_exists: true

    if column_exists?(:users, :email_address) && !column_exists?(:users, :email)
      remove_index :users, :email_address if index_exists?(:users, :email_address)
      rename_column :users, :email_address, :email
    end

    add_index :users, :email, unique: true unless index_exists?(:users, :email)

    create_table :sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :user_agent
      t.string :ip_address

      t.timestamps
    end
  end
end
