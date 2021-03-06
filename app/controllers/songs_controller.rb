class SongsController < ApplicationController
  load_and_authorize_resource

  before_filter :find_song, only: [:show, :play, :edit, :update, :destroy, :ban, :unban]

  def index
    @songs = Song.includes(:uploader).filter(params)
    @songs = @songs.unhidden unless is_admin?
    @songs = @songs.paginate(page: params[:page], per_page: 32)
  end

  def show
  end

  def play
    @volume = params[:volume] || "1.0"
    @seek = params[:seek] || 0

    #Convert to logrithmic scale
    @volume = (@volume.to_f ** 4.0).round(5).to_s
  end

  def new
    @song = Song.new
    @categories = Directory.where(parent: Directory.root).order(full_path: :asc)
  end

  def edit
    @directories = Directory.where(root: false).order(full_path: :asc)
  end

  def create
    path = params[:song][:path].downcase.tr("-\s\t()[]", "")
    category = params[:song][:category]
    @song = Song.new(create_params)
    @song.uploader = current_user
    @song.set_with_path_and_category path, category


    if @song.save

      #Check if we should add this song as a theme
      @song.reload
      if params[:song][:add_as_theme] == "1"
        Theme.create(user: current_user, song: @song)
      end

      #Alert user that song needs admin approval
      if @song.banned?
        flash[:error] = "Song requires admin approval."
      end

      flash[:notice] = "Successfully uploaded #{@song.full_path}."
      redirect_to @song
    else
      flash[:error] = @song.errors.full_messages.to_sentence
      redirect_to new_song_path
    end
  end

  def update
    if @song.update_attributes(update_params)
      @song.reload
      flash[:notice] = "Successfully updated #{@song.full_path}."
      redirect_to @song
    else
      flash[:error] = @song.errors.full_messages.to_sentence
      redirect_to edit_song_path @song
    end

  end

  def destroy
    @song.destroy
    redirect_to directory_path(@song.directory), notice: "Deleted #{@song.full_path}"
  end

  def ban
    if !@song.banned?
      @song.banned_at = Time.now
      @song.save!
      flash[:notice] = "Banned Song"
    else
      flash[:alert] = "Song already banned"
    end

    redirect_to @song
  end

  def unban
    @song.banned_at = nil
    @song.save!
    flash[:notice] = "Unbanned Song"
    redirect_to @song
  end

  private
  def create_params
    params.require(:song).permit(:sound)
  end

  def update_params
    authorize! :map_themeable, @song unless params[:song][:map_themeable].nil? && params[:song][:halloween_themeable].nil? && params[:song][:christmas_themeable].nil?
    authorize! :user_themeable, @song unless params[:song][:user_themeable].nil?
    params.require(:song).permit(:name, :directory_id, :title, :artist, :album, :map_themeable, :user_themeable, :halloween_themeable, :christmas_themeable)
  end

  def find_song
    @song = Song.find(params[:id])
  end

end
