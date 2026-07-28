class RenameCompanyIdentifierToSubdomain < ActiveRecord::Migration[8.0]
  def up
    remove_index :companies, name: "index_companies_on_identifier" if index_exists?(:companies, :identifier, name: "index_companies_on_identifier")
    rename_column :companies, :identifier, :subdomain if column_exists?(:companies, :identifier)
    add_index :companies,
              :subdomain,
              unique: true,
              where: "subdomain IS NOT NULL AND deleted_at IS NULL",
              name: "index_companies_on_subdomain" unless index_exists?(:companies, :subdomain, name: "index_companies_on_subdomain")
  end

  def down
    remove_index :companies, name: "index_companies_on_subdomain" if index_exists?(:companies, :subdomain, name: "index_companies_on_subdomain")
    rename_column :companies, :subdomain, :identifier if column_exists?(:companies, :subdomain)
    add_index :companies,
              :identifier,
              unique: true,
              where: "identifier IS NOT NULL AND deleted_at IS NULL",
              name: "index_companies_on_identifier" unless index_exists?(:companies, :identifier, name: "index_companies_on_identifier")
  end
end
