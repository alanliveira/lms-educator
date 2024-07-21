class ChangeColumnsToNotNull < ActiveRecord::Migration[7.1]
  def change
    change_column_null :users, :department, false
    change_column_null :users, :full_name, false
  end
end
