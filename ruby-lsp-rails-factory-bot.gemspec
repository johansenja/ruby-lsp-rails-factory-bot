# frozen_string_literal: true

require_relative "lib/ruby_lsp_rails_factory_bot"

Gem::Specification.new do |spec|
  spec.name = "ruby-lsp-rails-factory-bot"
  spec.version = RubyLsp::Rails::FactoryBot::VERSION
  spec.authors = ["johansenja"]
  spec.email = ["43235608+johansenja@users.noreply.github.com"]

  spec.summary = "A ruby-lsp-rails extension for factorybot"
  spec.description = "A ruby-lsp-rails extension for factorybot, providing factory, trait and attribute completion, and more"
  spec.homepage = "https://github.com/johansenja/ruby-lsp-factory-bot"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/johansenja/ruby-lsp-rails-factory-bot"
  spec.metadata["changelog_uri"] = "https://github.com/johansenja/ruby-lsp-rails-factory-bot"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "factory_bot", "~> 6.4.6"
  spec.add_dependency "ruby-lsp", "~> 0.17.17"
  spec.add_dependency "ruby-lsp-rails" #, "~> 0.3.13"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
