class CreateDocuments < ActiveRecord::Migration[7.2]
  def change
    create_table :documents do |t|
      t.belongs_to :folder, foreign_key: true
      t.string :name, null: false
      t.integer :status, default: 0, null: false
      t.timestamps
    end
  end
end
