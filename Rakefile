# encoding: utf-8
# -*- ruby -*-

$:.unshift File.join(File.dirname(__FILE__), "lib")

require 'rubygems'
require 'bundler/setup'

require "rake"
require "rake/clean"

require "fileutils"
require "i18n-init"

require 'i18n-init/version'
require 'hoe'

task :default => [:spec]

desc "install by setup.rb"
task :install do
  sh "sudo ruby setup.rb install"
end

### Gem

Hoe.plugin :bundler
Hoe.plugin :yard
Hoe.plugin :gemspec

Hoe.spec 'i18n-init' do
  developer               I18n::Init::DEVELOPER, I18n::Init::EMAIL

  self.version         =  I18n::Init::VERSION
  self.rubyforge_name  =  I18n::Init::NAME
  self.summary         =  I18n::Init::SUMMARY
  self.description     =  I18n::Init::DESCRIPTION
  self.url             =  I18n::Init::URL

  self.remote_rdoc_dir = ''
  self.rsync_args      << '--chmod=a+rX'
  self.readme_file     = 'README.md'
  self.history_file    = 'docs/HISTORY'

  extra_deps          << ['i18n', '>= 0.4.1']

  extra_dev_deps      << ['rspec',            '>= 2.6.0']   <<
                         ['yard',             '>= 0.8.2']   <<
                         ['rdoc',             '>= 3.8.0']   <<
                         ['redcarpet',        '>= 2.1.0']   <<
                         ['bundler',          '>= 1.0.10']  <<
                         ['hoe-bundler',      '>= 1.1.0']   <<
                         ['hoe-gemspec',      '>= 1.0.0']

  unless extra_dev_deps.flatten.include?('hoe-yard')
    extra_dev_deps << ['hoe-yard', '>= 0.1.2']
  end
end

task 'Manifest.txt' do
  puts 'generating Manifest.txt from git'
  sh %{git ls-files | grep -v gitignore > Manifest.txt}
  sh %{git add Manifest.txt}
end

task 'ChangeLog' do
  sh %{git log > ChangeLog}
end

desc "Fix documentation's file permissions"
task :docperm do
  sh %{chmod -R a+rX doc}
end

### Sign & Publish

desc "Create signed tag in Git"
task :tag do
  sh %{git tag -s v#{I18n::Init::VERSION} -m 'version #{I18n::Init::VERSION}'}
end

desc "Create external GnuPG signature for Gem"
task :gemsign do
  sh %{gpg -u #{I18n::Init::EMAIL} \
           -ab pkg/#{I18n::Init::NAME}-#{I18n::Init::VERSION}.gem \
            -o pkg/#{I18n::Init::NAME}-#{I18n::Init::VERSION}.gem.sig}
end

