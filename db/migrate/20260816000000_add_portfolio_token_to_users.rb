class AddPortfolioTokenToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :portfolio_token, :string
    add_index  :users, :portfolio_token, unique: true

    # Back-fill existing users with a unique secure token
    User.find_each do |user|
      user.update_columns(portfolio_token: SecureRandom.hex(16))
    end

    change_column_null :users, :portfolio_token, false
  end

  def down
    remove_column :users, :portfolio_token
  end
end
