# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_08_10_150000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "certificate_issuances", force: :cascade do |t|
    t.bigint "certificate_id", null: false
    t.bigint "course_id", null: false
    t.bigint "user_id", null: false
    t.string "verification_code", null: false
    t.datetime "completed_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["certificate_id", "user_id"], name: "index_certificate_issuances_on_certificate_id_and_user_id", unique: true
    t.index ["certificate_id"], name: "index_certificate_issuances_on_certificate_id"
    t.index ["course_id"], name: "index_certificate_issuances_on_course_id"
    t.index ["user_id"], name: "index_certificate_issuances_on_user_id"
    t.index ["verification_code"], name: "index_certificate_issuances_on_verification_code", unique: true
  end

  create_table "certificates", force: :cascade do |t|
    t.bigint "course_id", null: false
    t.text "description"
    t.integer "total_hours"
    t.jsonb "elements", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_certificates_on_course_id", unique: true
  end

  create_table "companies", force: :cascade do |t|
    t.string "name"
    t.string "fantasy_name"
    t.string "cnpj"
    t.string "address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "subdomain"
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_companies_on_deleted_at"
    t.index ["subdomain"], name: "index_companies_on_subdomain", unique: true, where: "((subdomain IS NOT NULL) AND (deleted_at IS NULL))"
  end

  create_table "company_courses", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.bigint "course_id", null: false
    t.boolean "can_be_viewed", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "can_be_viewed"], name: "index_company_courses_on_company_id_and_can_be_viewed"
    t.index ["company_id", "course_id"], name: "index_company_courses_on_company_id_and_course_id", unique: true
    t.index ["company_id"], name: "index_company_courses_on_company_id"
    t.index ["course_id"], name: "index_company_courses_on_course_id"
  end

  create_table "company_users", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.bigint "user_id", null: false
    t.boolean "owner"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["company_id", "user_id"], name: "index_company_users_on_company_id_and_user_id", unique: true, where: "(deleted_at IS NULL)"
    t.index ["company_id"], name: "index_company_users_on_company_id"
    t.index ["company_id"], name: "index_company_users_on_unique_active_owner", unique: true, where: "((owner = true) AND (deleted_at IS NULL))"
    t.index ["deleted_at"], name: "index_company_users_on_deleted_at"
    t.index ["user_id"], name: "index_company_users_on_user_id"
  end

  create_table "course_class_completions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "course_class_id", null: false
    t.datetime "completed_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_class_id"], name: "index_course_class_completions_on_course_class_id"
    t.index ["user_id", "course_class_id"], name: "index_course_class_completions_on_user_and_class", unique: true
    t.index ["user_id"], name: "index_course_class_completions_on_user_id"
  end

  create_table "course_classes", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "course_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.datetime "deleted_at"
    t.index ["course_id", "id"], name: "index_course_classes_on_course_id_and_id"
    t.index ["course_id"], name: "index_course_classes_on_course_id"
    t.index ["deleted_at"], name: "index_course_classes_on_deleted_at"
  end

  create_table "courses", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.datetime "deleted_at"
    t.integer "workload_hours"
    t.index ["deleted_at"], name: "index_courses_on_deleted_at"
  end

  create_table "histories", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "action"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_histories_on_user_id"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name"
    t.string "resource_type"
    t.bigint "resource_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id"
    t.index ["resource_type", "resource_id"], name: "index_roles_on_resource"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "created_at"], name: "index_sessions_on_user_id_and_created_at", order: { created_at: :desc }
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.boolean "verified", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active", default: false
    t.string "department", null: false
    t.string "full_name", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "users_roles", id: false, force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "role_id"
    t.index ["role_id"], name: "index_users_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id"
    t.index ["user_id"], name: "index_users_roles_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "certificate_issuances", "certificates"
  add_foreign_key "certificate_issuances", "courses"
  add_foreign_key "certificate_issuances", "users"
  add_foreign_key "certificates", "courses"
  add_foreign_key "company_courses", "companies"
  add_foreign_key "company_courses", "courses"
  add_foreign_key "company_users", "companies"
  add_foreign_key "company_users", "users"
  add_foreign_key "course_class_completions", "course_classes"
  add_foreign_key "course_class_completions", "users"
  add_foreign_key "course_classes", "courses"
  add_foreign_key "histories", "users"
  add_foreign_key "sessions", "users"
end
