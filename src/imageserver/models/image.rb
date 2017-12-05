require_relative 'image_uploader'

class Image < ActiveRecord::Base
  has_and_belongs_to_many :events
  mount_uploader :source, ImageUploader

  def post_image(post_image_data)
    tap do |image|
      timeobj = Time.now
      puts post_image_data
      if post_image_data && post_image_data[:filename]
        post_image_data[:filename] =
          "%s%s" % [ (timeobj.to_i.to_s +
                      timeobj.usec.to_s).ljust(16, '0'),
                     File.extname(post_image_data[:filename])]
      end
      image.source = post_image_data
    end
  end

  def url
    source.url
  end

  def remove_all_images
    remove_source!
  end

  private

  def all_image_details
    [source] + source.versions.values
  end
end
