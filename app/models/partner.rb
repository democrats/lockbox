class Partner < ActiveRecord::Base
  include RFC822
  validates_presence_of :api_key, :phone_number, :name, :organization, :email
  validates_format_of :email, :with => EmailAddressRegularExpression
  validates_uniqueness_of :api_key
  
  before_validation :create_api_key


  def phone_number
    (self.attributes["phone_number"] || "").to_phone(:area_code => true)
  end

  def phone_number=(_phone_number)
    @attributes["phone_number"] = _phone_number.to_s.gsub(/[^0-9]+/, '')
  end
  
  def cache_key
    "#{Time.now.strftime("#{api_key}_%m%d%y_%H")}"
  end
  
  def self.authenticate(api_key)  
    p = Partner.find_by_api_key(api_key)
    if p
      if p.max_requests.present?
        if p.current_request_count < p.max_requests
          p.increment_request_count
          return true
        else
          return false
        end
      else
        return true
      end
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
  
  def requests_remaining
    max_requests - current_request_count
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
