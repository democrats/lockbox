class CreatePartners < ActiveRecord::Migration
  def self.up
    create_table :partners do |t|
      t.string :name
      t.string :organization
      t.string :phone_number
      t.string :email
      t.string :api_key
      t.integer :max_requests
      
      t.timestamps
    end
  end

  def self.down
    drop_table :partners
  end
end
