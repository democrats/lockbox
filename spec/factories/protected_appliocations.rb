Factory.define :protected_application do |p|
  p.name              { Factory.next(:name) }
  p.description          { "foo"}
end

Factory.sequence(:name) do |n|
  "name#{n}"
end