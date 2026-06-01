class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :artworks, dependent: :destroy
  has_one_attached :avatar
  has_one_attached :cover_image

  def display_name
    name.presence || email.split("@").first.titleize
  end
end
