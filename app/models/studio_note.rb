class StudioNote < ApplicationRecord
  belongs_to :artwork

  validates :body, presence: true

  def self.ransackable_attributes(auth_object = nil)
    %w[body written_on]
  end
end
