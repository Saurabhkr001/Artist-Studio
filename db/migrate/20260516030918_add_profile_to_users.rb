class AddProfileToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :artist_statement, :text
    add_column :users, :contact_email, :string
  end
end
