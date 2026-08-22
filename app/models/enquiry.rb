class Enquiry < ApplicationRecord
  belongs_to :user
  belongs_to :artwork, optional: true

  validates :sender_name, presence: true
  validates :sender_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :message, presence: true
end
