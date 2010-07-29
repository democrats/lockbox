class CreateApplications < ActiveRecord::Migration
  def self.up
    create_table :protected_applications do |t|
      t.string :name
      t.string :description
      t.timestamps
    end

    create_table :partners_protected_applications, :id => false do |t|
      t.integer :partner_id
      t.integer :protected_application_id
    end

    add_index :partners_protected_applications, [:partner_id, :protected_application_id]
  end

  def self.down
    drop_table :protected_applications
    drop_table :partners_protected_applications
  end
end
