$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "rails_presenter/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rails_presenter"
  s.version     = RailsPresenter::VERSION
  s.authors     = ["Diego Mónaco"]
  s.email       = ["dfmonaco@gmail.com"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of RailsPresenter."
  s.description = "TODO: Description of RailsPresenter."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", "~> 3.2.11"
  # s.add_dependency "jquery-rails"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "capybara"
end
