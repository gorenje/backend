class Addresses < ActiveRecord::Migration[5.1]
  def change
    create_table :addresses do |t|
      t.string :street_1
      t.string :street_2
      t.string :zipcode
      t.string :city
      t.string :state
      t.string :country

      t.float :latitude
      t.float :longitude
      t.string :name

      t.belongs_to :user
      t.timestamps :null => false
    end
  end
end
