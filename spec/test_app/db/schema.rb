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

ActiveRecord::Schema[7.2].define(version: 2024_09_05_100636) do
  create_table "automatables", force: :cascade do |t|
    t.string "name", default: "A container", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "automations_actions", force: :cascade do |t|
    t.integer "automation_id", null: false
    t.integer "position", null: false
    t.string "name", default: "", null: false
    t.string "handler_class_name", default: "", null: false
    t.text "configuration_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["automation_id"], name: "index_automations_actions_on_automation_id"
  end

  create_table "automations_automations", force: :cascade do |t|
    t.string "container_type"
    t.integer "container_id"
    t.string "type"
    t.string "name", default: "", null: false
    t.integer "status", default: 0, null: false
    t.text "configuration_data"
    t.string "configuration_class_name", default: "", null: false
    t.string "before_trigger_class_name", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["container_id", "container_type", "status", "type"], name: "idx_on_container_id_container_type_status_type_88c50d46bb"
    t.index ["container_type", "container_id"], name: "index_automations_automations_on_container"
  end

  add_foreign_key "automations_actions", "automations_automations", column: "automation_id"
end
