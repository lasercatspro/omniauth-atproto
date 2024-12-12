lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'omniauth-atproto/version'

Gem::Specification.new do |spec|
  spec.name = 'omniauth-atproto'
  spec.version = OmniAuth::Atproto::VERSION
  spec.authors = ['frabr']
  spec.email = ['frabr@lasercats.fr']

  spec.summary = 'OmniAuth strategy for AtProto'
  spec.description = 'OmniAuth strategy for authenticating with AtProto services like Bluesky'
  spec.homepage = 'https://github.com/lasercats/omniauth-atproto'
  spec.license = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.6.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/master/CHANGELOG.md"

  spec.files = Dir['{bin,lib}/**/*', 'LICENSE', 'README.md']
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'atproto_client', '~> 0.1.4'
  spec.add_dependency 'didkit'
  spec.add_dependency 'faraday'
  spec.add_dependency 'jwt', '~> 2.7'
  spec.add_dependency 'omniauth-oauth2', '~> 1.8'
  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
