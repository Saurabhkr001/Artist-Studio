class Artwork < ApplicationRecord
  belongs_to :user
  has_many_attached :images
  has_many :artwork_locations, dependent: :destroy
  has_many :studio_notes, dependent: :destroy
  has_many :artwork_tags, dependent: :destroy
  has_many :tags, through: :artwork_tags

  def self.ransackable_attributes(auth_object = nil)
    %w[title medium year_created description status]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

  # def self.ransackable_attributes(auth_object = nil)
  #   %w[title medium year_created description status]
  # end

  def self.ransackable_associations(auth_object = nil)
    %w[tags]
  end

  enum :status, {
    in_progress: 0,
    available:   1,
    sold:        2,
    gifted:      3,
    exhibited:   4,
    archived:    5
  }

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true
  validate :at_least_one_image, on: :create

  before_validation :generate_slug, on: :create

  scope :publicly_visible, -> { where(is_public: true) }
  scope :this_day_in_studio, -> {
    where(
      "EXTRACT(month FROM painted_on) = ? AND EXTRACT(day FROM painted_on) = ?",
      Date.today.month, Date.today.day
    )
  }

  private

  def generate_slug
    return if title.blank?
    base = title.parameterize
    candidate = base
    n = 1
    while Artwork.exists?(slug: candidate)
      candidate = "#{base}-#{n}"
      n += 1
    end
    self.slug = candidate
  end

  def at_least_one_image
    errors.add(:images, "must include at least one image") unless images.attached?
  end
end
