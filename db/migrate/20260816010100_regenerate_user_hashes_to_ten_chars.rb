class RegenerateUserHashesToTenChars < ActiveRecord::Migration[8.1]
  def up
    charset = [*'a'..'z', *'A'..'Z', *'0'..'9']

    User.find_each do |user|
      new_hash = loop do
        candidate = Array.new(10) { charset.sample }.join
        break candidate unless User.exists?(user_hash: candidate)
      end
      user.update_columns(user_hash: new_hash)
    end
  end

  def down
    # No reversible — old hashes are gone
  end
end
