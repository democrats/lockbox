class AddPartnerSlug < ActiveRecord::Migration
  def self.up
    add_column :partners, :slug, :string
    add_index :partners, :slug
  end

  def self.down
    remove_column :partners, :slug
    remove_index :partners, :slug
  end
end
