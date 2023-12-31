# -*- encoding: utf-8 -*-
# stub: sdbm 1.0.0 ruby lib
# stub: ext/sdbm/extconf.rb

Gem::Specification.new do |s|
  s.name = "sdbm".freeze
  s.version = "1.0.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Yukihiro Matsumoto".freeze]
  s.date = "2017-12-11"
  s.description = "Provides a simple file-based key-value store with String keys and values.".freeze
  s.email = ["matz@ruby-lang.org".freeze]
  s.extensions = ["ext/sdbm/extconf.rb".freeze]
  s.files = ["ext/sdbm/extconf.rb".freeze]
  s.homepage = "https://github.com/ruby/sdbm".freeze
  s.licenses = ["BSD-2-Clause".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3.0".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Provides a simple file-based key-value store with String keys and values.".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<test-unit>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake-compiler>.freeze, [">= 0".freeze])
end
