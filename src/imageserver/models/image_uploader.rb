class ImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  def store_dir
    'public/images'
  end

  storage :fog

  version :thumb do
    process :resize_to_fill => [250,250]
  end

  version :icon do
    process :resize_to_fill => [30,30]
  end

  version :iconbigger do
    process :resize_to_fill => [60,60]
  end
end
