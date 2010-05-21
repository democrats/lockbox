class CreatePartners < ActiveRecord::Migration
  def self.up
    create_table :partners do |t|
      t.string    :name
      t.string    :organization
      t.string    :phone_number
      t.string    :api_key
      t.integer   :max_requests,        :default => 100
      t.string    :email,                                   :null => false
      t.string    :crypted_password,                        :null => false
      t.string    :password_salt,                           :null => false
      t.string    :persistence_token,                       :null => false
      t.string    :single_access_token,                     :null => false
      t.string    :perishable_token,                        :null => false
      t.integer   :login_count,         :default => 0,      :null => false
      t.integer   :failed_login_count,  :default => 0,      :null => false
      t.datetime  :last_request_at
      t.datetime  :current_login_at
      t.datetime  :last_login_at
      t.string    :current_login_ip
      t.string    :last_login_ip
      t.boolean   :active,              :default => true
      t.boolean   :confirmed,           :default => false

      t.timestamps
    end
    
    add_index :partners, :email
  end

  def self.down
    drop_table :partners
  end
end
