class ArtworkLocation < ApplicationRecord
  belongs_to :artwork
  validates :location_name, presence: true
end
