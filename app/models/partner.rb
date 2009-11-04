class Partner < ActiveRecord::Base
  include RFC822
  validates_presence_of :api_key, :phone_number, :name, :organization, :email
  validates_format_of :email, :with => EmailAddressRegularExpression
  before_validation :create_api_key


  def phone_number
    (self.attributes["phone_number"] || "").to_phone(:area_code => true)
  end

  def phone_number=(_phone_number)
    @attributes["phone_number"] = _phone_number.to_s.gsub(/[^0-9]+/, '')
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
