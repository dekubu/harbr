# -*- encoding: utf-8 -*-
# stub: resend 0.8.1 ruby lib

Gem::Specification.new do |s|
  s.name = "resend".freeze
  s.version = "0.8.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Derich Pacheco".freeze]
  s.date = "2023-12-14"
  s.email = "carlosderich@gmail.com".freeze
  s.homepage = "https://github.com/resend/resend-ruby".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.6".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "The Ruby and Rails SDK for resend.com".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<httparty>.freeze, [">= 0.19.1".freeze])
  s.add_development_dependency(%q<rails>.freeze, [">= 0".freeze])
end
