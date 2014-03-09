if Rails.env.test? or Rails.env.cucumber?

  CarrierWave.configure do |config|
    config.storage = :file
    config.enable_processing = false
  end

else

  CarrierWave.configure do |config|
    config.fog_credentials = {
      provider:                         'Google',
      google_storage_access_key_id:     ENV['GOOGLE_STORAGE_ACCESS_KEY_ID'],
      google_storage_secret_access_key: ENV['GOOGLE_STORAGE_SECRET_ACCESS_KEY']
    }
    config.fog_directory = ENV['GOOGLE_STORAGE_DIRECTORY']
    config.storage = :fog
  end

end
