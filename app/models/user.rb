class User < ActiveRecord::Base
  has_many :uploaded_songs, foreign_key: "uploader_id", class_name: "Song"
  has_many :themes
  has_many :theme_songs, through: :themes, source: :song

  scope :admins, -> {where admin: true}

  after_find :check_for_account_update

  validates :nickname, presence: true
  validates :uid, presence: true
  validates :uid, uniqueness: true
  validates :provider, presence: true

  before_save :check_if_head_admin

  def self.random
    offset(rand count).first
  end

  def self.filter attributes
    attributes.inject(self) do |scope, (key, value)|
      return scope if value.blank?
      case key.to_sym
      when :admin
        scope.where(admin: true)
      when :banned
        scope.where("banned_at > 0").order(banned_at: :desc)
      when :uploader
        scope.where(uploader: true)
      else
        all
      end
    end
  end

  def self.create_with_steam_id(steam_id)
    return nil if steam_id.nil?
    steam = SteamId.new(steam_id.to_i)
    create! do |user|
      user.provider = "steam"
      user.uid = steam.steam_id64.to_s
      user.nickname = steam.nickname
      user.avatar_url = steam.medium_avatar_url
      user.avatar_icon_url = steam.icon_url
    end
  end

  def self.create_with_omniauth(auth)
    create! do |user|
      user.provider = auth["provider"]
      user.uid = auth["uid"]
      user.nickname = auth["info"]["nickname"]
      user.avatar_url = auth["info"]["image"]
      user.avatar_icon_url = auth["extra"]["raw_info"]["avatar"]
    end
  end

  def steam_update
    steam = SteamId.new(uid.to_i)
    update_attributes(nickname: steam.nickname, avatar_url: steam.medium_avatar_url, avatar_icon_url: steam.icon_url)
    touch
  end

  def check_for_account_update
    if updated_at < 7.days.ago
      begin
        steam_update
      rescue SteamCondenserError
      end
    end
  end

  def profile_url
    "http://steamcommunity.com/profiles/#{uid}"
  end

  def banned?
    banned_at
  end

  def to_param
    uid.parameterize
  end

  private
  def check_if_head_admin
    if provider == "steam" && uid == ENV['STEAM_HEAD_ADMIN_ID']
      self.admin = true
    end
  end

end
