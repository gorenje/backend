class CreateNotifications < ActiveRecord::Migration[5.1]
  def change
    create_table :notifications do |t|
      t.belongs_to :user
      t.hstore     :payload
      t.datetime   :read_at
      t.timestamps :null => false
    end
  end
end
