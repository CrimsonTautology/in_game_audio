class ApiKey < ActiveRecord::Base
  validates :name, presence: true
  has_many :play_events

  before_create :generate_access_token

  def self.authenticate access_token
    ApiKey.find_by(access_token: access_token)
  end

  private

  def generate_access_token
    begin
      self.access_token = SecureRandom.hex
    end while ApiKey.exists?(access_token: access_token)
  end

end
