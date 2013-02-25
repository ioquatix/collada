# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'collada/version'

Gem::Specification.new do |gem|
	gem.name          = "collada"
	gem.version       = Collada::VERSION
	gem.authors       = ["Samuel Williams"]
	gem.email         = ["samuel.williams@oriontransfer.co.nz"]
	gem.description   = <<-EOF
	This library provides support for loading and processing data from Collada 
	Digital Asset Exchange files. These files are typically used for sharing
	geometry and scenes.
	EOF
	gem.summary       = %q{A library for loading and manipulating Collada .dae files.}
	gem.homepage      = ""

	gem.files         = `git ls-files`.split($/)
	gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
	gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
	gem.require_paths = ["lib"]
	
	gem.add_dependency "rainbow"
	gem.add_dependency "trollop"
	gem.add_dependency "libxml-ruby"
end
