class Partner < ActiveRecord::Base
  acts_as_authentic do |c|
    c.maintain_sessions = false
  end
  
  include RFC822
  validates_presence_of :phone_number, :name, :organization, :email
  validates_presence_of :api_key, :on => :update
  validates_format_of :email, :with => EmailAddressRegularExpression
  validates_uniqueness_of :api_key
  
  before_create :create_api_key
  
  MAX_RESPONSE_CACHE_TIME = 1.hour
  
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
    auth = authenticate(p)
    {:partner => p, :authorized => auth, :may_cache => p.max_requests.blank?}
  end

  def self.authenticate(p)
    p = Partner.find_by_api_key(p) if p.is_a?(String)
    if p
      return p if p.unlimited?
      return false if p.current_request_count >= p.max_requests
      p.increment_request_count
      return p
    end
    return false
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
    1.hour.since(Time.parse(Time.now.utc.strftime("%Y-%m-%d %H:00:00"))).to_i
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
  
  private
  
  def secure_digest(*args)
    Digest::SHA1.hexdigest(args.flatten.join('--'))
  end
  
  def make_api_key
    secure_digest(Time.now, (1..10).map{ rand.to_s })
  end
  
  def create_api_key
    write_attribute :api_key, make_api_key
  end
end
