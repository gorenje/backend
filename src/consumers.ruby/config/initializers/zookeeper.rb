require 'zk'

module ZkClient
  extend self

  def broker_list
    begin
      [].tap do |broker_list|
        zk = ZK.new(ENV['ZOOKEEPER_HOST'])
        zk.children("/brokers/ids").each do |broker_id|
          data = JSON(zk.get("/brokers/ids/#{broker_id}").first)
          broker_list << data["endpoints"]
        end
        zk.close
      end.flatten
    rescue Exception => e
      puts "Not able to get broker list: #{e.message}"
      []
    end
  end
end
