require 'zk'

module ZkClient
  extend self

  def broker_list
    [].tap do |broker_list|
      zk = ZK.new(ENV['ZOOKEEPER_HOST'])
      zk.children("/brokers/ids").each do |broker_id|
        data = JSON(zk.get("/brokers/ids/#{broker_id}").first)
        broker_list << data["endpoints"]
      end
      zk.close
    end.flatten
  end
end
