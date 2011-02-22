Gem::Specification.new do |s|
  s.name = %q{memcache_array}
  s.version = "1.0"
  s.date = %q{2011-02-22}
  s.authors = ["Florian Odronitz"]
  s.email = %q{odo@mac.com}
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.summary = %q{MemcacheArray is a wrapper for Memcache so it can be used as shared memory holding arrays.}
  s.homepage = %q{http://github.com/traveliq/memcache_array}
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.5.0}
  s.files = [ "README.rdoc", "LICENSE", "lib/memcache_array.rb"]
  s.test_files = [ "spec/memcache_array_spec.rb"]
  s.add_dependency(%q<rspec>, ["~> 2.3.0"])
end