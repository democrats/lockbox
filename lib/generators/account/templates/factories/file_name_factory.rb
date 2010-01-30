Factory.sequence(:email) do |n|
  "test_#{n}@test.com"
end

Factory.define :<%= singular_name %> do |p|
  p.email                 { Factory.next(:email) }
  p.password              { "password" }
  p.password_confirmation { "password" }
  p.confirmed             { true }
end