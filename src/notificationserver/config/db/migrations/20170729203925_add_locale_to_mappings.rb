class AddLocaleToMappings < ActiveRecord::Migration[5.1]
  def change
    add_column :mappings, :locale, :string
  end
end
