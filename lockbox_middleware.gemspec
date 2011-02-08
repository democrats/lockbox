# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{lockbox_middleware}
  s.version = "1.6.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Chris Gill", "Nathan Woodhull", "Brian Cardarella", "Wes Morgan", "Dave Steinberg"]
  s.date = %q{2011-02-04}
  s.description = %q{Rack middleware for the LockBox centralized API authorization service. Brought to you by the DNC Innovation Lab.}
  s.email = %q{innovationlab@dnc.org}
  s.extra_rdoc_files = [
    "LICENSE",
    "README.rdoc"
  ]
  s.files = [
    "lib/lockbox_cache.rb",
    "lib/lockbox_middleware.rb",
    "lib/hmac_request.rb"
  ]
  s.homepage = %q{http://github.com/dnclabs/lockbox}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Rack middleware for the LockBox centralized API authorization service.}
  s.test_files = [
    "spec/lib/lockbox_cache_spec.rb",
    "spec/lib/lockbox_middleware_spec.rb",
    "spec/spec.opts",
    "spec/spec_helper.rb",
    "spec/support/helper_methods.rb",
    "spec/support/mocha.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rack>, [">= 0"])
      s.add_runtime_dependency(%q<httpotato>, [">= 0"])
      s.add_runtime_dependency(%q<dnclabs-auth-hmac>, [">= 0"])
    else
      s.add_dependency(%q<rack>, [">= 0"])
      s.add_dependency(%q<httpotato>, [">= 0"])
      s.add_dependency(%q<dnclabs-auth-hmac>, [">= 0"])
    end
  else
    s.add_dependency(%q<rack>, [">= 0"])
    s.add_dependency(%q<httpotato>, [">= 0"])
    s.add_dependency(%q<dnclabs-auth-hmac>, [">= 0"])
  end
end

