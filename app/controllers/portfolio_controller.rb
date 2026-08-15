class PortfolioController < ApplicationController
  layout false
  skip_before_action :verify_authenticity_token, only: []

  # ── /portfolio  (logged-in owner's own view) ─────────────────────────────
  def index
    @user = current_user
    return redirect_to new_user_session_path unless @user

    load_artworks
    load_tags
  end

  def show
    @user = current_user
    return redirect_to new_user_session_path unless @user

    find_artwork_or_redirect(portfolio_path)
  end

  # ── /:user_hash/portfolio  (public shareable link) ─────────────────────────
  def public_index
    @user = User.find_by(user_hash: params[:user_hash])
    return render_not_found unless @user

    load_artworks
    load_tags
    render :index
  end

  def public_show
    @user = User.find_by(user_hash: params[:user_hash])
    return render_not_found unless @user

    find_artwork_or_redirect(public_portfolio_path(params[:user_hash]))
    render :show if performed? == false
  end

  private

  def load_artworks
    @artworks = @user.artworks.publicly_visible

    if params[:status].present? && Artwork.statuses.key?(params[:status])
      @artworks = @artworks.public_send(params[:status])
    end

    if params[:tag].present?
      @artworks = @artworks.joins(:tags).where(tags: { name: params[:tag] })
    end

    @artworks = @artworks.order(painted_on: :desc, created_at: :desc)
    @pagy, @artworks = pagy(@artworks, limit: 12)
  end

  def load_tags
    @all_tags = Tag.joins(:artworks)
                   .where(artworks: { user_id: @user.id, is_public: true })
                   .distinct
                   .order(:name)
  end

  def find_artwork_or_redirect(fallback_path)
    @artwork = @user.artworks
                    .publicly_visible
                    .find_by(slug: params[:slug])
    redirect_to fallback_path, alert: "Artwork not found." if @artwork.nil?
  end

  def render_not_found
    render plain: "Portfolio not found.", status: :not_found
  end
end
