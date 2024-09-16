class CreateAutomationsActions < ActiveRecord::Migration[7.1]
  def change
    create_table :automations_actions do |t|
      t.belongs_to :automation, foreign_key: {to_table: "automations_automations"}, null: false
      t.integer :position, null: false
      t.string :name, null: false, default: ""
      t.string :handler_class_name, null: false, default: ""
      t.text :configuration_data
      t.timestamps
    end
  end
end
