class CreateArtworkLocations < ActiveRecord::Migration[8.1]
  def change
    create_table :artwork_locations do |t|
      t.references :artwork, null: false, foreign_key: true
      t.string :location_name
      t.date :moved_on
      t.text :notes

      t.timestamps
    end
  end
end
