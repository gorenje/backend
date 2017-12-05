class Tables < ActiveRecord::Migration[5.1]
  def change
    create_table(:images) do |t|
      t.text :source
      t.string :state

      t.timestamps(:null => false)
    end

    create_table(:events) do |t|
      t.string :name
      t.string :state

      t.string :frequency
      t.string :occurance

      t.datetime :startdate
      t.datetime :enddate

      t.json :details
      t.timestamps(:null => false)
    end

    create_table(:events_images, :id => false) do |t|
      t.integer :event_id, :index => [:events, :both]
      t.integer :image_id, :index => [:images, :both]
    end
  end
end
