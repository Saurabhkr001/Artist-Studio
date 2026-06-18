class PortfolioController < ApplicationController
  layout false
  # No authentication — this is public
  skip_before_action :verify_authenticity_token, only: []

  def index
    @user = current_user
    @artworks = @user.artworks.publicly_visible

    if params[:status].present? && Artwork.statuses.key?(params[:status])
      @artworks = @artworks.public_send(params[:status])
    end

    if params[:tag].present?
      @artworks = @artworks.joins(:tags).where(tags: { name: params[:tag] })
    end

    @artworks = @artworks.order(painted_on: :desc, created_at: :desc)
    @pagy, @artworks = pagy(@artworks, limit: 12)
    @all_tags = Tag.joins(:artworks).where(artworks: { user_id: @user.id, is_public: true }).distinct.order(:name)
  end

  def show
    @user = current_user
    @artwork = @user.artworks
                    .publicly_visible
                    .find_by(slug: params[:slug])
    if @artwork.nil?
      redirect_to portfolio_path, alert: "Artwork not found."
    end
  end
end
