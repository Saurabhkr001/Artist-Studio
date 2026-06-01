class CreateStudioNotes < ActiveRecord::Migration[8.1]
  def change
    create_table :studio_notes do |t|
      t.references :artwork, null: false, foreign_key: true
      t.text :body
      t.date :written_on

      t.timestamps
    end
  end
end
