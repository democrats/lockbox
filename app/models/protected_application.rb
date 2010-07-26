# == Schema Information
# Schema version: 20100726221934
#
# Table name: protected_applications
#
#  id          :integer         not null, primary key
#  name        :string(255)
#  description :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#

class ProtectedApplication < ActiveRecord::Base
  validates_uniqueness_of :name
  has_and_belongs_to_many :partners
end
