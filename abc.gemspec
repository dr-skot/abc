# -*- encoding: utf-8 -*-
require File.expand_path('../lib/abc/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Scott Shepherd"]
  gem.email         = ["skot@pobox.com"]
  gem.description   = %q{working with ABC music notation}
  gem.summary       = %q{working with ABC music notation}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "abc"
  gem.require_paths = ["lib"]
  gem.version       = ABC::VERSION
end
