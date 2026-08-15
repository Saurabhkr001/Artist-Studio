class RenamePortfolioTokenToUserHash < ActiveRecord::Migration[8.1]
  def up
    rename_column :users, :portfolio_token, :user_hash

    # Remove any existing index on the old or new column name (defensive)
    %w[index_users_on_portfolio_token index_users_on_user_hash].each do |idx|
      remove_index :users, name: idx if index_name_exists?(:users, idx)
    end

    # Ensure a clean unique index under the correct name
    add_index :users, :user_hash, unique: true, name: "index_users_on_user_hash"
  end

  def down
    remove_index :users, name: "index_users_on_user_hash" if index_name_exists?(:users, "index_users_on_user_hash")
    rename_column :users, :user_hash, :portfolio_token
    add_index :users, :portfolio_token, unique: true, name: "index_users_on_portfolio_token"
  end
end
