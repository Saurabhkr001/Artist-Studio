class ProfileController < ApplicationController
  before_action :authenticate_user!

  def edit
  end

  def update
    p_params = profile_params
    if current_user.update(p_params)
      current_user.avatar.purge if ActiveModel::Type::Boolean.new.cast(params[:remove_avatar] || params.dig(:user, :remove_avatar)) && p_params[:avatar].blank?
      current_user.cover_image.purge if ActiveModel::Type::Boolean.new.cast(params[:remove_cover_image] || params.dig(:user, :remove_cover_image)) && p_params[:cover_image].blank?

      redirect_to edit_profile_path, notice: "Profile updated successfully.", status: :see_other
    else
      flash.now[:alert] = "Failed to update profile."
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:user).permit(:name, :artist_statement, :contact_email, :avatar, :cover_image)
  end
end
