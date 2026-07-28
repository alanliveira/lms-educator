class AddTenantIntegrityIndexes < ActiveRecord::Migration[8.0]
  def change
    add_index :companies,
              :identifier,
              unique: true,
              where: "identifier IS NOT NULL AND deleted_at IS NULL"

    add_index :company_courses,
              [:company_id, :course_id],
              unique: true

    add_index :company_users,
              [:company_id, :user_id],
              unique: true,
              where: "deleted_at IS NULL"

    add_index :company_users,
              [:company_id],
              unique: true,
              where: "owner = TRUE AND deleted_at IS NULL",
              name: "index_company_users_on_unique_active_owner"
  end
end
