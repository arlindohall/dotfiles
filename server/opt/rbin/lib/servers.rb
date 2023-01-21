class Server
  attr_reader :name, :port

  def install
    puts "No-op install for server #{name}:#{port}"
  end

  def start
    raise "Must implement start for server #{name}"
  end
end

class StaticHomesite < Server
end

class Pihole < Server
end

class BabyBuddy < Server
end
