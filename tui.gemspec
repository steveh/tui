# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "tui/version"

Gem::Specification.new do |s|
  s.name        = "tui"
  s.version     = Tui::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Steve Hoeksema"]
  s.email       = ["steve@seven.net.nz"]
  s.homepage    = ""
  s.summary     = "A collection of command line utilities to interact with tu.is"
  s.description = "A collection of command line utilities to interact with tu.is"

  s.rubyforge_project = "tui"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
