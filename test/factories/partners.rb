Factory.define :partner do |p|
  p.name                  { "George Washington"}
  p.organization          { "Cherry Tree Cutters"}
  p.email                 { Factory.next(:email) }
  p.phone_number          { "1112223333"}
  p.max_requests          { 100 }
  p.api_key               { Factory.next(:api_key) }
  p.password              { "password" }
  p.password_confirmation { "password" }
  p.confirmed             { true }
end

Factory.sequence(:api_key) do |n|
  "#{n}"
end

Factory.sequence(:email) do |n|
  "george_#{n}@ctc.com"
end