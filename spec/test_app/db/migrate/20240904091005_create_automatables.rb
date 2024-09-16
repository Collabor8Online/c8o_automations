class CreateAutomatables < ActiveRecord::Migration[7.2]
  def change
    create_table :automatables do |t|
      t.string :name, default: "A container", null: false
      t.timestamps
    end
  end
end
