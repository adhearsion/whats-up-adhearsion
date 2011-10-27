GEM_FILES = %w{
  lib/whats-up-adhearsion.rb
  config/whats-up-adhearsion.yml
}

Gem::Specification.new do |s|
  s.name = "whats-up-adhearsion"
  s.version = "0.1.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Lance Gleason"]

  s.date = Date.today.to_s
  s.description = "Allows you to get information about Adhearsions status via rest calls"
  s.email = "dev&adhearsion.com"

  s.files = GEM_FILES

  s.has_rdoc = false
  s.homepage = "https://github.com/adhearsion/whats-up-adhearsion"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.2.0"
  s.summary = "Provides a RESTful status for Adhearsion"

  s.specification_version = 2

  s.add_dependency "adhearsion"
  s.add_dependency "json"
  s.add_dependency "rack"
  s.add_dependency "mongrel" , '>= 1.2.0.pre2'
  s.add_development_dependency "rspec"
  s.add_development_dependency "flexmock"
  s.add_development_dependency "jeweler"
  s.add_development_dependency "activerecord"
end
