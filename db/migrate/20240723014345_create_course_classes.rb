class CreateCourseClasses < ActiveRecord::Migration[7.1]
  def change
    create_table :course_classes do |t|
      t.string :name, null: false
      t.references :course, null: false, foreign_key: true

      t.timestamps
    end
  end
end
