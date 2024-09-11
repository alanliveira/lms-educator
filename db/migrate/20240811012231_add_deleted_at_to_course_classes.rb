class AddDeletedAtToCourseClasses < ActiveRecord::Migration[7.1]
  def change
    add_column :course_classes, :deleted_at, :datetime
    add_index :course_classes, :deleted_at
  end
end
