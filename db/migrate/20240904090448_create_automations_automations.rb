class CreateAutomationsAutomations < ActiveRecord::Migration[7.1]
  def change
    create_table :automations_automations do |t|
      t.belongs_to :container, polymorphic: true
      t.string :type
      t.string :name, default: "", null: false
      t.integer :status, default: 0, null: false
      t.text :configuration_data
      t.string :configuration_class_name, null: false, default: ""
      t.string :before_trigger_class_name, null: false, default: ""
      t.timestamps
    end

    add_index :automations_automations, [:container_id, :container_type, :status, :type]
  end
end
