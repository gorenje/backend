class RemoveEvents < ActiveRecord::Migration[5.1]
  def up
    drop_table :events
    drop_table :events_images
  end
end
