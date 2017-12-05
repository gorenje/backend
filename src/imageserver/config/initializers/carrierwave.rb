require 'carrierwave'
require 'carrierwave/storage'

CarrierWave.configure do |config|
  config.fog_provider = 'fog/aws'
  config.fog_credentials = {
    :provider               => 'AWS',
    :aws_access_key_id      => ENV['BUCKETEER_AWS_ACCESS_KEY_ID'],
    :aws_secret_access_key  => ENV['BUCKETEER_AWS_SECRET_ACCESS_KEY'],
  }
  config.fog_directory  = ENV['BUCKETEER_BUCKET_NAME']
  config.fog_public     = false
  config.fog_attributes = {'Cache-Control'=>'max-age=315576000'}
end
