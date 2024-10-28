# frozen_string_literal: true

require_relative "lib/yabeda/activejob/version"

Gem::Specification.new do |spec|
  spec.name                     = "yabeda-activejob"
  spec.version                  = Yabeda::ActiveJob::VERSION
  spec.authors                  = ["Fullscript"]
  spec.email                    = ["josh.etsenake@fullscript.com"]
  spec.summary                  = "Yabeda Prometheus exporter for monitoring your activejobs"
  spec.description              = "Prometheus exporter for collecting metrics around your activejobs"
  spec.homepage                 = "https://github.com/Fullscript/yabeda-activejob"
  spec.license                  = "MIT"
  spec.required_ruby_version    = ">= 3.0"
  spec.files                    = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.metadata["homepage_uri"]          = spec.homepage
  spec.metadata["source_code_uri"]       = spec.homepage
  spec.metadata["changelog_uri"]         = "#{spec.homepage}/CHANGELOG.md"

  spec.add_dependency "rails", ">= 6.1"
  spec.add_dependency "yabeda", "~> 0.6"
end
