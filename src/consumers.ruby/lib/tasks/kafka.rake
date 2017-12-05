namespace :kafka do
  namespace :offset do

    desc <<-EOF
      Get all current offsets.
    EOF
    task :get_all => :environment do
      $collection = []
      module ObtainDetails
        def start_kafka_stream(name, group_id, topics, loop_count)
          $collection << {
            :client_id => name,
            :group => group_id,
            :topic => topics,
          }
        end
        def start_kafka_stream_by_message(name, group_id, topics, loop_count)
          $collection << {
            :client_id => name,
            :group => group_id,
            :topic => topics,
          }
        end
      end

      [Consumers::Clickstats,
       Consumers::Clickstore,
       Consumers::Postbacks,
       Consumers::Attribution,
       Consumers::Conversion,
      ].each do |klz|
        klz.send(:include, ObtainDetails)
        klz.new.perform
      end

      puts "Getting current offset"
      $collection.each do |args|
        consumer = $kafka[args[:client_id]].consumer(:group_id => args[:group])
        consumer.subscribe(args[:topic])
        consumer.send(:join_group)
        om = consumer.instance_variable_get("@offset_manager")
        args.merge!(:offset => om.next_offset_for(args[:topic], 0))
      end

      puts "Getting current earliest offsets"
      $collection.each do |args|
        consumer = $kafka[args[:client_id]].
          consumer(:group_id => SecureRandom.uuid)
        consumer.subscribe(args[:topic], :default_offset => :earliest)
        consumer.each_message(:loop_count => 1) do |msg|
          if args[:earliest].nil? or args[:earliest] > msg.offset
            args.merge!(:earliest => msg.offset)
          end
        end
      end

      puts $collection
      $collection.each do |args|
        puts "rake kafka:offset:set[#{args[:client_id]},#{args[:group]},#{args[:topic]},0,#{args[:earliest]-1}]"
      end
    end

    desc <<-EOF
      Get the current offset.
    EOF
    task :get, [:client_id, :group, :topic, :partition] => :environment do |t,args|
      [:client_id,:group, :topic, :partition].each do |p|
        raise "No #{p} given" if args[p].blank?
      end

      consumer = $kafka[args[:client_id]].consumer(:group_id => args[:group])
      consumer.subscribe(args[:topic])
      consumer.send(:join_group)
      om = consumer.instance_variable_get("@offset_manager")
      puts om.next_offset_for(args[:topic], args[:partition].to_i)

    end

    desc <<-EOF
      Set the current offset.
    EOF
    task :set, [:client_id, :group, :topic, :partition, :offset] => :environment do |t,args|
      [:client_id,:group, :topic, :partition, :offset].each do |p|
        raise "No #{p} given" if args[p].blank?
      end

      consumer = $kafka[args[:client_id]].consumer(:group_id => args[:group])
      consumer.subscribe(args[:topic])
      consumer.send(:join_group)
      om = consumer.instance_variable_get("@offset_manager")
      om.mark_as_processed(args[:topic], args[:partition].to_i,
                           args[:offset].to_i)
      puts om.commit_offsets
    end

    desc <<-EOF
      Get the earliest offset.
    EOF
    task :earliest, [:client_id, :topic, :partition] => :environment do |t,args|
      [:client_id, :topic, :partition].each do |p|
        raise "No #{p} given" if args[p].blank?
      end

      consumer = $kafka[args[:client_id]].
        consumer(:group_id => SecureRandom.uuid)
      consumer.subscribe(args[:topic], :default_offset => :earliest)
      consumer.each_message(:loop_count => 1) do |msg|
        puts msg.offset
        exit
      end
    end

    desc <<-EOF
      Get the latest offset.
    EOF
    task :latest, [:client_id, :topic, :partition] => :environment do |t,args|
      [:client_id, :topic, :partition].each do |p|
        raise "No #{p} given" if args[p].blank?
      end

      consumer = $kafka[args[:client_id]].
        consumer(:group_id => SecureRandom.uuid)
      consumer.subscribe(args[:topic], :default_offset => :latest)
      consumer.each_message(:loop_count => 1) do |msg|
        puts msg.offset
        exit
      end
    end

  end
end
