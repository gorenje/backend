class InitialTables < ActiveRecord::Migration[4.2]
  def change
    create_table :users do |t|
      t.string   :email, :index => true
      t.string   :name
      t.hstore   :address
      t.boolean  :email_verified
      t.string   :language
      t.datetime :join_date
      t.text     :credentials

      t.string  :salt
      t.string  :confirm_token
      t.boolean :has_confirmed, :default => false

      t.timestamps :null => false
    end
  end
end
