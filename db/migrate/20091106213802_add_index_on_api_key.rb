class AddIndexOnApiKey < ActiveRecord::Migration
  def self.up
    add_index :partners, :api_key
  end

  def self.down
    remove_index :partners, :api_key    
  end
end
