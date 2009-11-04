Factory.define :partner do |p|
  p.name { "George Washington"}
  p.organization { "Cherry Tree Cutters"}
  p.email { "george@ctc.com"}
  p.api_key        { Factory.next(:api_key) }
end

Factory.sequence(:api_key) do |n|
  "#{n}"
end