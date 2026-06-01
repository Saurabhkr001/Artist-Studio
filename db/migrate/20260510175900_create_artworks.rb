class CreateArtworks < ActiveRecord::Migration[8.1]
  def change
    create_table :artworks do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.string :medium
      t.string :dimensions_cm
      t.integer :year_created
      t.text :description
      t.integer :status, default: 0, null: false
      t.boolean :is_public, default: false, null: false
      t.string :slug, null: false
      t.date :painted_on

      t.timestamps
    end

    add_index :artworks, :slug, unique: true
    add_index :artworks, :status
    add_index :artworks, [ :user_id, :is_public ]
  end
end
