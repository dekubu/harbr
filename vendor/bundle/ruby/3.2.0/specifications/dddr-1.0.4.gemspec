# -*- encoding: utf-8 -*-
# stub: dddr 1.0.4 ruby lib

Gem::Specification.new do |s|
  s.name = "dddr".freeze
  s.version = "1.0.4".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "homepage_uri" => "https://gitlab.com/dekubu/dddr" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Delaney Burke".freeze]
  s.bindir = "exe".freeze
  s.date = "2023-12-06"
  s.description = "DDDr stands for Domain Driven Design Data Repository. It's a Ruby gem that simplifies the implementation of data repositories in a Domain-Driven Design (DDD) architecture.\nIt offers a clean interface for abstracting data access, allowing you to focus on your domain logic rather than database operations.\nWith DDDr, you can easily swap out data sources without affecting your core business logic.\n".freeze
  s.email = ["delaney@vidtreone.com".freeze]
  s.homepage = "https://gitlab.com/dekubu/dddr".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.6.0".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Domain Driven Design Data Repository".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<sdbm>.freeze, ["~> 1.0".freeze])
end
