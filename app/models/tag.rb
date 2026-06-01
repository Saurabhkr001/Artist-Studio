class Tag < ApplicationRecord
  has_many :artwork_tags, dependent: :destroy
  has_many :artworks, through: :artwork_tags

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  before_save :normalize_name

  def self.ransackable_attributes(auth_object = nil)
    %w[name]
  end

  private

  def normalize_name
    self.name = name.downcase.strip.gsub(/\s+/, "-").gsub(/[^a-z0-9\-]/, "")
  end
end
