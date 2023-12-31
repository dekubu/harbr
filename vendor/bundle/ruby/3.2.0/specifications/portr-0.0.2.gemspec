# -*- encoding: utf-8 -*-
# stub: portr 0.0.2 ruby lib

Gem::Specification.new do |s|
  s.name = "portr".freeze
  s.version = "0.0.2".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/dekubu/portr/blob/main/CHANGELOG.md", "homepage_uri" => "https://github.com/your-username/portr", "source_code_uri" => "https://github.com/dekubu/portr" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Delaney Burke".freeze]
  s.bindir = "exe".freeze
  s.date = "2023-12-09"
  s.description = "Portr is a Ruby gem manages a pool of ports".freeze
  s.email = ["delaney@vidtreone.com".freeze]
  s.executables = ["port".freeze]
  s.files = ["exe/port".freeze]
  s.homepage = "https://github.com/your-username/portr".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.6.0".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Portr is a Ruby gem manages a pool of ports".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<thor>.freeze, ["~> 1.0".freeze])
  s.add_runtime_dependency(%q<json>.freeze, ["~> 2.3".freeze])
end
