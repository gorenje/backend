class AddLatLngBoundsToAddresses < ActiveRecord::Migration[5.1]
  def change
    add_column :addresses, :bounds, :hstore
  end
end
