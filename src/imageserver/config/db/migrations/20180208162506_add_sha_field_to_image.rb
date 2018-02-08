class AddShaFieldToImage < ActiveRecord::Migration[5.1]
  def change
    add_column :images, :sha, :string, :length => 64, :default => nil
    add_index :images, :sha
  end
end
