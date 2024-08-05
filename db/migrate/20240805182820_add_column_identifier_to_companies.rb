class AddColumnIdentifierToCompanies < ActiveRecord::Migration[7.1]
  def change
    add_column :companies, :identifier, :string
  end
end
