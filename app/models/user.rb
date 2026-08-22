class User < ApplicationRecord
  has_many :enquiries, dependent: :destroy
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :timeoutable

  has_many :artworks, dependent: :destroy
  has_one_attached :avatar
  has_one_attached :cover_image

  before_create :generate_user_hash

  def display_name
    name.presence || email.split("@").first.titleize
  end

  def achievements_list
    achievements.to_s.split("\n").map(&:strip).reject(&:blank?)
  end

  private

  def generate_user_hash
    charset = [*'a'..'z', *'A'..'Z', *'0'..'9']
    loop do
      self.user_hash = Array.new(10) { charset.sample }.join
      break unless User.exists?(user_hash: user_hash)
    end
  end
end
