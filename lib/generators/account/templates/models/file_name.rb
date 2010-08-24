class <%= class_name %> < ActiveRecord::Base

  acts_as_authentic do |c|
    c.maintain_sessions = false
  end
  
end
