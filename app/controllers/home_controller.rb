class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    @current_user = current_user
    @artworks_today = current_user.artworks.this_day_in_studio
    @recent_artworks = current_user.artworks.order(created_at: :desc).limit(6)
    @counts = {
      total:       current_user.artworks.count,
      available:   current_user.artworks.available.count,
      sold:        current_user.artworks.sold.count,
      in_progress: current_user.artworks.in_progress.count
    }
  end

  def analytics
    artworks = current_user.artworks

    @total       = artworks.count
    @public      = artworks.where(is_public: true).count
    @status_data = Artwork.statuses.keys.map { |s| [ s, artworks.public_send(s).count ] }.to_h
    @by_year     = artworks.where.not(year_created: nil)
                          .group(:year_created).count.sort.to_h
    @by_medium   = artworks.where.not(medium: nil)
                          .group(:medium).count
                          .sort_by { |_, v| -v }.first(6).to_h
    @top_tags    = Tag.joins(:artworks)
                      .where(artworks: { user_id: current_user.id })
                      .group("tags.name").count
                      .sort_by { |_, v| -v }.first(8).to_h
    @this_day    = artworks.this_day_in_studio.count
  end
  def credits
    render :credits
  end
end
