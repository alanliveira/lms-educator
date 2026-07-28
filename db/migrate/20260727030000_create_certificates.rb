class CreateCertificates < ActiveRecord::Migration[8.0]
  def change
    create_table :certificates do |t|
      t.references :course, null: false, foreign_key: true, index: { unique: true }
      t.text :description
      t.integer :total_hours
      t.jsonb :elements, null: false, default: {}

      t.timestamps
    end
  end
end
