class StudioNotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_artwork

  def create
    @note = @artwork.studio_notes.new(note_params)
    @note.written_on = Date.today

    if @note.save
      redirect_to artwork_path(@artwork.slug), notice: "Letter saved."
    else
      redirect_to artwork_path(@artwork.slug), alert: "Couldn't save your letter."
    end
  end

  def destroy
    @note = @artwork.studio_notes.find(params[:id])
    @note.destroy
    redirect_to artwork_path(@artwork.slug), notice: "Letter removed."
  end

  private

  def set_artwork
    @artwork = current_user.artworks.find_by!(slug: params[:artwork_slug])
  end

  def note_params
    params.require(:studio_note).permit(:body)
  end
end
