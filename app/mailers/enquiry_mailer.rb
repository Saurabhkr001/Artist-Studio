class EnquiryMailer < ApplicationMailer
  default from: 'no-reply@thestudio.com'

  def new_enquiry
    @enquiry = params[:enquiry]
    @artist = @enquiry.user
    
    mail(
      to: @artist.contact_email.presence || @artist.email,
      subject: "New Studio Enquiry from #{@enquiry.sender_name}"
    )
  end
end
