class AddSendbirdToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :sendbird_userid, :string, :length => 80
  end
end
