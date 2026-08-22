class CreateEnquiries < ActiveRecord::Migration[8.1]
  def change
    create_table :enquiries do |t|
      t.references :user, null: false, foreign_key: true
      t.references :artwork, null: true, foreign_key: true
      t.string :sender_name
      t.string :sender_email
      t.text :message

      t.timestamps
    end
  end
end
