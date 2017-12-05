namespace :i18n do
  desc <<-EOF
    Showing missing translations - reminds me to use i18n-tasks.
  EOF
  task :show_missing => :environment do
    system("i18n-tasks missing")
  end
end
