source 'https://rubygems.org'

ENV['TEST_VAGRANT_VERSION'] ||= 'v1.9.3'

# Wrapping gemspec in the :plugins group causes Vagrant 1.5 and newer to
# automagically load this plugin during acceptance tests.
group :plugins do
  gemspec
end

group :development do
  gem 'yard', '~> 0.8.7'
  gem 'redcarpet'
end

group :test do
  if ENV['TEST_VAGRANT_VERSION'] == 'HEAD'
    gem 'vagrant', :github => 'mitchellh/vagrant', :branch => 'master'
  else
    gem 'vagrant', :github => 'mitchellh/vagrant', :tag => ENV['TEST_VAGRANT_VERSION']
    # FIXME: Hack to allow Vagrant v1.6.5 to install for tests. Remove when
    # support for 1.6.5 is dropped.
    gem 'rack', '< 2'
  end

  # Pinned on 12/10/2014. Compatible with Vagrant 1.6.x, 1.7.x and 1.8.x.
  gem 'vagrant-spec', :github => 'mitchellh/vagrant-spec', :ref => '1df5a3a'
end

eval_gemfile "#{__FILE__}.local" if File.exists? "#{__FILE__}.local"
