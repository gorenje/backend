namespace :sendbird do
  desc <<-EOF
    Delete a channel.
  EOF
  task :delete_group_channel, [:url] => :environment do |t,args|
    puts SendbirdApi.new.group_channels.send(args.url).delete
  end

  desc <<-EOF
    Return all group channels.
  EOF
  task :group_channels => :environment do |t,args|
    SendbirdApi.new.group_channels.get("limit=99")["channels"].
      each do |channel|
      ch = OpenStruct.new(channel)
      puts "------------------------"
      puts "Name: #{ch.name}"
      puts "URL: #{ch.channel_url}"
      puts "Members: #{ch.member_count}"

      SendbirdApi.new.group_channels.send(ch.channel_url).
        get("show_member=true")["members"].
        each do |member|
        puts "   - #{member['user_id']}"
      end
    end
  end

  desc <<-EOF
    Defines the task fubar:snafu:doit
  EOF
  task :send_message, [:url, :msg, :userid] => :environment do |t,args|
    data = {
      "message_type" => "MESG",
      "user_id"      => args.userid,
      "message"      => args.msg
    }

    puts SendbirdApi.new.group_channels.send(args.url).messages.post(data)
  end
end
