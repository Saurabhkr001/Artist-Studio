class AddReadToEnquiries < ActiveRecord::Migration[8.1]
  def change
    add_column :enquiries, :read, :boolean, default: false, null: false
  end
end
