# frozen_string_literal: true

require_relative "lib/harbr/version"

Gem::Specification.new do |spec|
  spec.name = "harbr"
  spec.version = Harbr::VERSION
  spec.authors = ["Delaney Kuldvee Burke"]
  spec.email = ["delaney@zero2one.ee"]

  spec.summary = "A server-side tool for managing and deploying Rack applications."
  spec.description = "Harbr is a versatile tool designed to streamline the deployment, management, and scaling of Rack-based applications. It integrates with version control and process supervision systems to ensure smooth and consistent application delivery."
  spec.homepage = "https://github.com/delaneyburke/harbr"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/delaneyburke/harbr"
  spec.metadata["changelog_uri"] = "https://github.com/delaneyburke/harbr/CHANGELOG.md"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependencies can be added here. For example, if you use Net::SSH or similar gems:
  spec.add_dependency "listen", "~> 3.8"
  spec.add_dependency "thor", "~> 1.3"
  spec.add_dependency "dddr", "~> 1.0.3"
  spec.add_dependency "sucker_punch", "~> 3.1.0"
  spec.add_dependency "terminal-table", "3.0.2"
end
