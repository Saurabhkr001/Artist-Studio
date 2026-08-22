class EnquiriesController < ApplicationController
  before_action :authenticate_user!, only: [:index, :show, :destroy]
  layout -> { ['new', 'create'].include?(action_name) ? false : 'application' }

  def new
    @user = User.find_by!(user_hash: params[:user_hash])
    @artwork = @user.artworks.find_by(slug: params[:artwork_slug]) if params[:artwork_slug]
    @enquiry = Enquiry.new
  end

  def create
    @user = User.find_by!(user_hash: params[:user_hash])
    @enquiry = @user.enquiries.build(enquiry_params)
    
    if params[:enquiry][:artwork_id].present?
      @enquiry.artwork = @user.artworks.find_by(id: params[:enquiry][:artwork_id])
    end

    if @enquiry.save
      EnquiryMailer.with(enquiry: @enquiry).new_enquiry.deliver_later
      redirect_to public_portfolio_path(@user.user_hash), notice: "Your enquiry has been sent successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def index
    @pagy, @enquiries = pagy(current_user.enquiries.order(created_at: :desc), limit: 15)
  end

  def show
    @enquiry = current_user.enquiries.find(params[:id])
    unless @enquiry.read?
      @enquiry.update(read: true)
    end
  end

  def destroy
    @enquiry = current_user.enquiries.find(params[:id])
    @enquiry.destroy
    redirect_to enquiries_path, notice: "Enquiry deleted."
  end

  private
  def enquiry_params
    params.require(:enquiry).permit(:sender_name, :sender_email, :message)
  end
end
