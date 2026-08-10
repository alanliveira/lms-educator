class AddPerformanceIndexes < ActiveRecord::Migration[8.0]
  def change
    add_index :company_courses, [:company_id, :can_be_viewed]
    add_index :course_classes, [:course_id, :id]
    add_index :sessions, [:user_id, :created_at], order: { created_at: :desc }
  end
end
