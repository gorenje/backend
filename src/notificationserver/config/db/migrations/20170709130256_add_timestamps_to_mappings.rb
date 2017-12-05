class AddTimestampsToMappings < ActiveRecord::Migration[5.1]
  def change
    change_table :mappings do |t|
      t.timestamps :null => true
    end
  end
end
