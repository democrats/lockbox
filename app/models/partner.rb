# == Schema Information
# Schema version: 20100726221934
#
# Table name: partners
#
#  id                  :integer         not null, primary key
#  name                :string(255)
#  organization        :string(255)
#  phone_number        :string(255)
#  api_key             :string(255)
#  max_requests        :integer         default(100)
#  email               :string(255)     not null
#  crypted_password    :string(255)     not null
#  password_salt       :string(255)     not null
#  persistence_token   :string(255)     not null
#  single_access_token :string(255)     not null
#  perishable_token    :string(255)     not null
#  login_count         :integer         default(0), not null
#  failed_login_count  :integer         default(0), not null
#  last_request_at     :datetime
#  current_login_at    :datetime
#  last_login_at       :datetime
#  current_login_ip    :string(255)
#  last_login_ip       :string(255)
#  active              :boolean         default(TRUE)
#  confirmed           :boolean
#  created_at          :datetime
#  updated_at          :datetime
#  slug                :string(255)
#

class Partner < ActiveRecord::Base

  has_and_belongs_to_many :protected_applications


  class CredentialStore
    def [](access_key_id)
      p = Partner.find_by_slug(access_key_id)
      p.api_key if p
    end
  end
  
  acts_as_authentic do |c|
    c.maintain_sessions = false
  end
  
  before_validation_on_create :create_api_key, :create_slug
  
  include RFC822
  validates_presence_of :phone_number, :name, :organization, :email, :api_key
  validates_format_of :email, :with => EmailAddressRegularExpression
  validates_uniqueness_of :api_key
  validates_uniqueness_of :slug
  
  MAX_RESPONSE_CACHE_TIME = 1.hour
  
  def self.credential_store
    @cr ||= CredentialStore.new
  end
  
  def max_response_cache_time
    MAX_RESPONSE_CACHE_TIME
  end
  
  def phone_number
    (self.attributes["phone_number"] || "").to_phone(:area_code => true)
  end
  
  def phone_number=(_phone_number)
    @attributes["phone_number"] = _phone_number.to_s.gsub(/[^0-9]+/, '')
  end
  
  def cache_key
    cache_timestamp = 1.hour.until(Time.at(max_requests_reset_time)).strftime("%m%d%y_%H")
    "#{Time.now.strftime("#{api_key}_#{cache_timestamp}")}"
  end
  
  def self.find_and_authenticate(api_key)
    p = Partner.find_by_api_key(api_key)
    auth = authenticate(p).authorized
    {:partner => p, :authorized => auth, :may_cache => p.max_requests.blank?}
  end

  def self.authenticate(p)
    if p.is_a?(String)
      p = find_by_api_key(p)
    end
    if p && !p.unlimited?
      p.increment_request_count
    else
      p = new
    end
    p
  end
  
  def current_request_count
    count = Rails.cache.read(cache_key, :raw => true)
    if count.nil?
      count = 0
      Rails.cache.write(cache_key, count, :raw => true)
    end
    count.to_i
  end

  def max_requests_reset_time
    1.hour.since(Time.parse(Time.now.strftime("%Y-%m-%d %H:00:00"))).to_i
  end

  def unlimited?
    max_requests.blank?
  end
  
  def requests_remaining
    max_requests.blank? ? nil : max_requests - current_request_count
  end
  
  def increment_request_count
    ret = Rails.cache.increment(cache_key)
    if ret.nil?
      ret = 1
      Rails.cache.write(cache_key, ret, :raw => true)
    end
    ret.to_i
  end
  
  def authorized(application_name = '')
    return false unless id
    return false if !authorized_for_application?(application_name)
    if unlimited?
      true
    elsif requests_remaining > 0
      true
    else
      false
    end
  end

  def authorized_for_application?(application_name)
    if application_name.blank?
      return true
    else
      return protected_applications.collect{|pa| pa.name}.include?(application_name)
    end
  end
  
  private
  
  def secure_digest(*args)
    Digest::SHA1.hexdigest(args.flatten.join('--'))
  end
  
  def make_api_key
    secure_digest(Time.now, (1..10).map{ rand.to_s })
  end
  
  def create_api_key
    write_attribute :api_key, make_api_key unless api_key.present?
  end
  
  def make_slug
    if organization.present?
      "#{organization}-#{name}".parameterize
    elsif name.present?
      name.parameterize
    else
      rand(36**8).to_s(36)
    end
  end
  
  def create_slug
    write_attribute :slug, make_slug unless slug.present?
  end
end
