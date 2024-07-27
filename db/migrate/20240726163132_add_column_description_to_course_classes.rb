class AddColumnDescriptionToCourseClasses < ActiveRecord::Migration[7.1]
  def change
    add_column :course_classes, :description, :text
  end
end
