class InitialDatabase < ActiveRecord::Migration[5.1]
  def change
    create_table :mappings do |t|
      t.string :onesignal_id, :index => true
      t.string :sendbird_id, :index => true
      t.string :device_id, :index => true
    end
  end
end
