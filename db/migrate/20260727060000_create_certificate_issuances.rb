class CreateCertificateIssuances < ActiveRecord::Migration[8.0]
  def change
    create_table :certificate_issuances do |t|
      t.references :certificate, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :verification_code, null: false
      t.datetime :completed_at, null: false
      t.timestamps
    end

    add_index :certificate_issuances, :verification_code, unique: true
    add_index :certificate_issuances, %i[certificate_id user_id], unique: true
  end
end
