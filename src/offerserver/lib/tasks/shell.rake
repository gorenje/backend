desc "Start a pry shell and load all gems"
task :shell => :environment do
  require 'pry'

  Pry.editor = ENV['PRY_EDITOR'] || ENV['EDITOR'] || 'vi'
  Pry.start
end
