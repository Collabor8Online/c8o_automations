class CreateFolders < ActiveRecord::Migration[7.2]
  def change
    create_table :folders do |t|
      t.belongs_to :project, foreign_key: {to_table: "automatables"}
      t.belongs_to :parent, foreign_key: {to_table: "folders"}
      t.string :name, null: false
      t.timestamps
    end
  end
end
