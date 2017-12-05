class AddCallbackUrlToMappings < ActiveRecord::Migration[5.1]
  def change
    add_column :mappings, :callback_url, :text
  end
end
