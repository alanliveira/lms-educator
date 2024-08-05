class RenameDepartamentColumnToDepartment < ActiveRecord::Migration[7.1]
  def change
    rename_column :users, :departament, :department
  end
end
