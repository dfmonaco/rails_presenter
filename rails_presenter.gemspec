# encoding: utf-8

$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "rails_presenter/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rails_presenter"
  s.version     = RailsPresenter::VERSION
  s.authors     = ["Diego Mónaco"]
  s.email       = ["dfmonaco@gmail.com"]
  s.homepage    = "https://github.com/dfmonaco/rails_presenter"
  s.summary     = "Presenters for Rails applications"
  s.description = "Presenters for Rails applications"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", ">= 5.0.0.beta3", "< 5.1"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "pry-byebug"
end
