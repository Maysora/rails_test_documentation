require_relative "lib/rails_test_documentation/version"

Gem::Specification.new do |s|
  s.name        = 'rails_test_documentation'
  s.version     = RailsTestDocumentation::VERSION.dup
  s.platform    = Gem::Platform::RUBY
  s.date        = '2016-02-24'
  s.summary     = 'Generate rails test documentation.'
  s.description = 'Generate rails test documentation.'
  s.authors     = ['Roy Hadrianoro']
  s.email       = 'dev@maysora.com'
  s.files       = Dir.glob('lib/**/*') + ["README.md"]
  s.homepage    = 'https://github.com/Maysora/rails_test_documentation'
  s.license     = 'MIT'
  s.add_dependency("rails", ">= 4.2.0", "< 5.1")
end
