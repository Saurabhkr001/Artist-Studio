class ArtworksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_artwork, only: [ :show, :edit, :update, :destroy ]

  def index
    @q = current_user.artworks.ransack(params[:q])
    @q.sorts = "created_at desc" if @q.sorts.empty?
    @artworks = @q.result(distinct: true)

    if params[:status].present? && Artwork.statuses.key?(params[:status])
      @artworks = @artworks.public_send(params[:status])
    end

    if params[:tag].present?
      @artworks = @artworks.joins(:tags).where(tags: { name: params[:tag] })
    end

    @pagy, @artworks = pagy(@artworks, limit: 12)
  end

  def show
  end

  def new
    @artwork = current_user.artworks.new
  end

  def create
    @artwork = current_user.artworks.new(artwork_params)
    if @artwork.save
      save_tags(@artwork)
      redirect_to @artwork, notice: "Artwork added to your studio."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @artwork.update(artwork_params)
      save_tags(@artwork)
      redirect_to @artwork, notice: "Artwork updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @artwork.destroy
    redirect_to artworks_path, notice: "Artwork removed from your studio."
  end

  def catalogue
    @artworks = current_user.artworks
                            .where(is_public: true)
                            .order(year_created: :desc)

    pdf = generate_catalogue_pdf(@artworks)
    send_data pdf.render,
              filename: "studio_catalogue_#{Date.today.year}.pdf",
              type: "application/pdf",
              disposition: "attachment"
  end

  private

  def set_artwork
    @artwork = current_user.artworks.find_by!(slug: params[:slug])
  end

  def artwork_params
    params.require(:artwork).permit(
      :title, :medium, :dimensions_cm, :year_created,
      :description, :status, :is_public, :painted_on,
      images: []
    )
  end

  def save_tags(artwork)
    return unless params[:tag_list].present?
    tag_names = params[:tag_list].split(",").map(&:strip).reject(&:blank?)
    tags = tag_names.map do |name|
      Tag.find_or_create_by(name: name.downcase.strip.gsub(/\s+/, "-").gsub(/[^a-z0-9\-]/, ""))
    end
    artwork.tags = tags
  end

  # for pdf
  def generate_catalogue_pdf(artworks)
    Prawn::Document.new(page_size: "A4", margin: [ 50, 50, 50, 50 ]) do |pdf|
      page_width  = pdf.bounds.width   # 495
      page_height = pdf.bounds.height  # 742

      # ── COVER PAGE ──
      pdf.move_down page_height / 2 - 60

      pdf.text "STUDIO CATALOGUE",
        size: 8, character_spacing: 4, color: "5a4e3a", align: :center

      pdf.move_down 16

      pdf.text "Works & Studies",
        size: 32, style: :bold, color: "1a1209", align: :center

      pdf.move_down 10

      pdf.stroke do
        pdf.stroke_color "c4933f"
        pdf.line_width 0.5
        pdf.horizontal_line 200, 295, at: pdf.cursor
      end

      pdf.move_down 16

      pdf.text "#{Date.today.year}  ·  #{artworks.count} works",
        size: 8, character_spacing: 2, color: "3a3028", align: :center

      # ── ARTWORK PAGES ──
      artworks.each_with_index do |artwork, index|
        pdf.start_new_page

        # Try to load image and detect orientation
        img_data   = nil
        is_landscape = false

        if artwork.images.attached?
          begin
            img_data = artwork.images.first.download
            blob     = artwork.images.first.blob
            w        = blob.metadata["width"].to_f
            h        = blob.metadata["height"].to_f
            is_landscape = w > 0 && h > 0 && w > h
          rescue
            img_data = nil
            is_landscape = false
          end
        end

        top = pdf.bounds.top

        if is_landscape
          # ── LANDSCAPE: image full width, details below ──
          img_height = (page_width * 0.55).round

          begin
            pdf.image StringIO.new(img_data),
              width: page_width,
              height: img_height,
              position: :left
          rescue
            pdf.fill_color "1a1612"
            pdf.fill_rectangle [ 0, top ], page_width, img_height
            pdf.fill_color "000000"
          end

          pdf.move_down 24

          # Two columns for details
          col_w = (page_width - 24) / 2

          pdf.bounding_box([ 0, pdf.cursor ], width: col_w) do
            pdf.text "#{(index + 1).to_s.rjust(3, '0')}",
              size: 7, character_spacing: 2, color: "3a3028"
            pdf.move_down 8
            pdf.text artwork.title,
              size: 18, style: :bold, color: "1a1209", leading: 3
            pdf.move_down 8
            pdf.stroke do
              pdf.stroke_color "c4933f"
              pdf.line_width 0.5
              pdf.horizontal_line 0, 25, at: pdf.cursor
            end
          end

          pdf.bounding_box([ col_w + 24, pdf.cursor + 48 ], width: col_w) do
            [
              [ "Medium",     artwork.medium ],
              [ "Year",       artwork.year_created&.to_s ],
              [ "Dimensions", artwork.dimensions_cm.present? ? "#{artwork.dimensions_cm} cm" : nil ],
              [ "Status",     artwork.status&.humanize ]
            ].each do |label, value|
              next if value.blank?
              pdf.text label.upcase, size: 6, character_spacing: 2, color: "5a4e3a"
              pdf.move_down 2
              pdf.text value, size: 9, color: "3a3028"
              pdf.move_down 8
            end

            if artwork.description.present?
              pdf.text "ABOUT", size: 6, character_spacing: 2, color: "5a4e3a"
              pdf.move_down 2
              pdf.text artwork.description, size: 8, color: "6a5e4e", leading: 3
            end
          end

        else
          # ── PORTRAIT: image left, details right ──
          img_w = (page_width * 0.52).round
          img_h = [ (img_w * 1.25).round, page_height - 80 ].min

          begin
            pdf.image StringIO.new(img_data),
              fit: [ img_w, img_h ],
              position: :left
          rescue
            pdf.fill_color "1a1612"
            pdf.fill_rectangle [ 0, top ], img_w, img_h
            pdf.fill_color "000000"
          end if img_data

          detail_x = img_w + 28
          detail_w = page_width - detail_x

          pdf.bounding_box([ detail_x, top ], width: detail_w) do
            pdf.text "#{(index + 1).to_s.rjust(3, '0')}",
              size: 7, character_spacing: 2, color: "3a3028"
            pdf.move_down 14

            pdf.text artwork.title,
              size: 20, style: :bold, color: "1a1209", leading: 3
            pdf.move_down 12

            pdf.stroke do
              pdf.stroke_color "c4933f"
              pdf.line_width 0.5
              pdf.horizontal_line 0, 25, at: pdf.cursor
            end
            pdf.move_down 16

            [
              [ "Medium",     artwork.medium ],
              [ "Year",       artwork.year_created&.to_s ],
              [ "Dimensions", artwork.dimensions_cm.present? ? "#{artwork.dimensions_cm} cm" : nil ],
              [ "Status",     artwork.status&.humanize ],
              [ "Date",       artwork.painted_on&.strftime("%B %Y") ]
            ].each do |label, value|
              next if value.blank?
              pdf.text label.upcase, size: 6, character_spacing: 2, color: "5a4e3a"
              pdf.move_down 2
              pdf.text value, size: 9, color: "3a3028"
              pdf.move_down 10
            end

            if artwork.description.present?
              pdf.move_down 4
              pdf.text "ABOUT", size: 6, character_spacing: 2, color: "5a4e3a"
              pdf.move_down 4
              pdf.text artwork.description,
                size: 8, color: "6a5e4e", leading: 4
            end
          end
        end

        # Page number — bottom right
        pdf.bounding_box([ 0, 16 ], width: page_width) do
          pdf.text "#{index + 1} / #{artworks.count}",
            size: 7, character_spacing: 2, color: "c4933f", align: :right
        end
      end
    end
  end
end
