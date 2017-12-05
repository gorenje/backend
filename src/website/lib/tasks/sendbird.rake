namespace :sendbird do
  namespace :users do
    desc <<-EOF
      Create a new user.
    EOF
    task :create, [:user_id] => :environment do |t,args|
      puts SendbirdApi.new.users.post(:user_id     => args.user_id,
                                      :nickname    => args.user_id,
                                      :profile_url => "")
    end

    desc <<-EOF
      Delete ueser with user_id.
    EOF
    task :delete, [:user_id] => :environment do |t,args|
      puts SendbirdApi.new.users.send(args.user_id).delete
    end

    desc <<-EOF
      List all users.
    EOF
    task :list => :environment do |t,args|
      cnt = 0
      SendbirdApi.new.users._get_paginator({:limit => 15}) do |user_data|
        user_data["users"].each do |user|
          usr = OpenStruct.new(user)

          puts "------------------------ #{cnt+=1} -"
          puts "UserId: #{usr.user_id}"
          puts "Name: #{usr.nickname}"
          puts "Profile URL: #{usr.profile_url}"
          puts "Active/Online: #{usr.is_active} / #{usr.is_online}"
          puts "Last Seen: #{usr.last_seen_at}"
        end
      end
    end
  end

  namespace :group_channels do
    desc <<-EOF
      Delete a channel.
    EOF
    task :delete, [:url] => :environment do |t,args|
      puts SendbirdApi.new.group_channels.send(args.url).delete
    end

    desc <<-EOF
      Delete group channels by membership.
    EOF
    task :delete_with_member, [:member] => :environment do |t,args|
      SendbirdApi.new.group_channels._get_paginator({:limit => 15}) do |chdata|
        chdata["channels"].each do |channel|
          ch = OpenStruct.new(channel)

          members = SendbirdApi.new.group_channels.send(ch.channel_url).
            get("show_member=true")["members"].map { |m| m['user_id'] }

          if members.include?(args.member)
            puts SendbirdApi.new.group_channels.send(ch.channel_url).delete
          end
        end
      end
    end

    desc <<-EOF
      Delete group channels that have one member.
    EOF
    task :delete_with_one_member => :environment do |t,args|
      SendbirdApi.new.group_channels._get_paginator({:limit => 15}) do |chdata|
        chdata["channels"].each do |channel|
          ch = OpenStruct.new(channel)

          if ch.member_count == 1
            puts SendbirdApi.new.group_channels.send(ch.channel_url).delete
          end
        end
      end
    end

    desc <<-EOF
      Members of group channel.
    EOF
    task :members, [:channel_url] => :environment do |t,args|
      SendbirdApi.new.group_channels.send(args.channel_url).
        get("show_member=true")["members"].
        each do |member|
        puts "   - #{member['user_id']}"
      end
    end

    desc <<-EOF
      List all group channels.
    EOF
    task :list => :environment do |t,args|
      cnt = 0
      SendbirdApi.new.group_channels._get_paginator({:limit => 15}) do |chdata|
        chdata["channels"].each do |channel|
          ch = OpenStruct.new(channel)
          puts "------------------------ #{cnt+=1} -"
          puts "Name: #{ch.name}"
          puts "URL: #{ch.channel_url}"
          puts "Data: #{ch.data}"
          puts "Members: #{ch.member_count}"

          SendbirdApi.new.group_channels.send(ch.channel_url).
            get("show_member=true")["members"].
            each do |member|
            puts "   - #{member['user_id']}"
          end
        end
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
