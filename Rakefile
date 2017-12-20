require 'rubygems'
require 'bundler'
require 'bundler/setup'

KubernetesNS = 'pushtech'

require_relative 'lib/helpers'

Dir[File.join(File.dirname(__FILE__), 'lib', 'tasks','*.rake')].each do |f|
  load f
end

desc "Start a pry shell"
task :shell do
  require 'pry'
  Pry.editor = ENV['PRY_EDITOR'] || ENV['EDITOR'] || 'emacs'
  Pry.start
end

### ignore this stuff.
task :check_env do
  require 'yaml'
  Dir.glob("kubernetes/*deployment*").each do |file_name|
    hsh = YAML.load_file( file_name )
    values = []

    hsh["spec"]["template"]["spec"]["containers"].each do |container|
      (container["env"]||[]).each do |varn|
        next if varn["valueFrom"]
        next if varn["name"] =~ /_HOST$/
        next if ["PORT","COOKIE_SECRET","RACK_ENV"].include?(varn["name"])
        next if varn["name"] == "POSTGRES_PASSWORD" && varn["value"] == "nicesecret"
        values << varn
      end
    end

    unless values.empty?
      puts "==========> #{file_name}"
      values.each {|a| puts a }
    end
  end
end
