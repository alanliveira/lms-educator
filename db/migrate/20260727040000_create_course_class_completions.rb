class CreateCourseClassCompletions < ActiveRecord::Migration[8.0]
  def change
    create_table :course_class_completions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :course_class, null: false, foreign_key: true
      t.datetime :completed_at, null: false
      t.timestamps
    end

    add_index :course_class_completions, %i[user_id course_class_id], unique: true,
              name: "index_course_class_completions_on_user_and_class"
  end
end
