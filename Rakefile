require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "jquery_on_rails"
    gem.summary = %Q{JQuery on Rails - Replace prototype/scriptaculous with jquery}
    gem.description = %Q{A complete replacement for Rails 3 javascript helpers and unobstrusive javacript (ujs) using JQuery instead of prototype/scriptaculous}
    gem.email = "joe@ankhcraft.com"
    gem.homepage = "http://github.com/joekhoobyar/jquery_on_rails"
    gem.authors = ["Joe Khoobyar"]
    gem.files = Dir["{lib,public,spec}/**/*", "{bin}/*", "*"]
    gem.rubyforge_project = "jquery_on_rails"
    gem.add_dependency "actionpack", ">= 3.0.0.beta1"
    gem.add_development_dependency "rspec", ">= 1.2.9"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
  Jeweler::RubyforgeTasks.new do |rubyforge|
    rubyforge.doc_task = "rdoc"
  end
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "jquery_on_rails #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end