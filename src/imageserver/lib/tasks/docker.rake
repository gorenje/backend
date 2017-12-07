require 'socket'

namespace :docker do
  def are_all_migrations_up?
    ActiveRecord::Migrator.migrations_status(["."]).
      map(&:first).all?{ |status| status == "up" }
  end

  task :pause_for_db do
    host, port =
          ENV["DATABASE_URL"].split(/@/).last.split(/\//).first.split(/:/)
    puts "Pinging: #{host} @ #{port}"

    t = Thread.new { sleep(10); Kernel.exit(false) }

    begin
      port = port.to_i
      addr = Socket.getaddrinfo(host, port)
      sock = Socket.new(Socket.const_get(addr[0][0]), Socket::SOCK_STREAM, 0)

      sock.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
      sock.connect(Socket.pack_sockaddr_in(port, addr[0][3]))
      Kernel.exit(true)
    rescue Errno::ECONNREFUSED => e
      puts "!!! Can't connect"
      retry
    end
  end

  task :create_postgres_extensions do
    conn = ActiveRecord::Base.connection
    conn.execute( "create extension hstore;") rescue nil
    conn.execute( "create extension plpgsql;") rescue nil
  end

  task :if_db_not_migrated do
    begin
      exit(!are_all_migrations_up?)
    rescue
      exit(true)
    end
  end

  task :if_db_is_migrated do
    begin
      exit(are_all_migrations_up?)
    rescue
      exit(false)
    end
  end
end
