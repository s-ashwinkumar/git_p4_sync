# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'git_p4_sync/version'

Gem::Specification.new do |spec|
  spec.name          = "git_p4_sync"
  spec.version       = GitP4Sync::VERSION
  spec.authors       = ["Ashwin Kumar Subramanian"]
  spec.email         = ["s.ashwinkumar2490@gmail.com"]

  spec.summary       = %q{Git to Perforce synchronization}
  spec.description   = %q{This gem can be used to submit all the changes made in a git repository into a perforce repo.}
  spec.homepage      = "https://github.com/s-ashwinkumar/git_p4_sync"
  spec.license       = "MIT"

  spec.files         = Dir['Rakefile', '{bin,lib,man,spec}/**/*', 'README*', 'LICENSE*'] & `git ls-files -z`.split("\0")
  # spec.bindir        = "exe"
  spec.executables = ["git_p4_sync"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_dependency "diff_dirs", "~> 0.1.2"
end
