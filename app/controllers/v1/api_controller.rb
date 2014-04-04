module V1
  class ApiController < ApplicationController
    skip_before_filter :verify_authenticity_token
    authorize_resource class: false
    before_filter :check_api_key
    before_filter :check_path, only: [:query_song]
    before_filter :check_uid,  only: [:query_song, :user_theme, :authorize_user]
    before_filter :check_user, only: [:query_song, :authorize_user]
    before_filter :check_map,  only: [:map_theme]

    before_filter :get_pall
    before_filter :get_force

    respond_to :json

    def query_song
      song = Song.path_search @path

      if song.nil?
        out = {
          found: false,
          command: "query_song"
        }
      else
        #Create a play event for this song
        play_event = PlayEvent.create(song: song, type_of: (@pall ? "pall" : "p"), user: @user, api_key: @api_key )
        play_event.save

        out = {
          found: true,
          command: "query_song",
          pall: @pall,
          force: @force,
          access_token: play_event.access_token
        }.merge song.to_json_api
      end
      render json: out
    end

    def user_theme
      user = User.find_by_uid(@uid)

      if user.nil?
        out = {
          found: false,
          command: "user_theme"
        }
      else
        song = user.theme_songs.random
        if song.nil?
          out = {
            found: false,
            command: "user_theme"
          }
        else
          #Create a play event for this song
          play_event = PlayEvent.create(song: song, type_of: "user", api_key: @api_key )
          play_event.save

          out = {
            found: true,
            command: "user_theme",
            pall: true,
            force: @force,
            access_token: play_event.access_token
          }.merge song.to_json_api
        end
      end
      render json: out
    end

    def map_theme
      song = Song.where(map_themeable: true).random

      if song.nil?
        out = {
          found: false,
          command: "map_theme"
        }
      else
        play_event = PlayEvent.create(song: song, type_of: "map", api_key: @api_key )
        play_event.save

        out = {
          found: true,
          command: "map_theme",
          pall: true,
          force: @force,
          access_token: play_event.access_token
        }.merge song.to_json_api
      end
      render json: out
    end

    def authorize_user
      @user.uploader = true
      @user.save
      out = {
        uid: @uid,
        command: "authorize_user"
      }

      render json: out
    end


    private
    def check_api_key
      @api_key = ApiKey.authenticate(params[:access_token])
      head :unauthorized unless @api_key
    end

    def check_path
      @path = params["path"]
      head :bad_request unless @path
    end

    def check_uid
      @uid = params["uid"]
      head :bad_request unless @uid
    end

    def check_user
      @user = User.find_by(provider: "steam", uid: @uid) || User.create_with_steam_id(@uid)
      head :bad_request unless @user
    end

    def check_map
      @map = params["map"]
      head :bad_request unless @map
    end

    def get_pall
      @pall = params["pall"] == 'true' || params["pall"] == "1"
    end

    def get_force
      @force = params["force"] == 'true' || params["force"] == "1"
    end

  end
end

