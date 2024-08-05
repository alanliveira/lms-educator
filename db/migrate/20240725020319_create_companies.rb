class CreateCompanies < ActiveRecord::Migration[7.1]
  def change
    create_table :companies do |t|
      t.string :name
      t.string :fantasy_name
      t.string :cnpj
      t.string :address

      t.timestamps
    end
  end
end
