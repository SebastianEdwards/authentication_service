class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :email
      t.string :password_digest
      t.string :provider_uid
      t.string :provider_type
      t.string :authenticatable_id
      t.string :authenticatable_type

      t.timestamps
    end
  end

  def self.down
    drop_table :users
  end
end
