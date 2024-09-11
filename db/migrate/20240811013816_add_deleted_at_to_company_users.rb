class AddDeletedAtToCompanyUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :company_users, :deleted_at, :datetime
    add_index :company_users, :deleted_at
  end
end
