# typed: false
require "erb"
require "pathname"

$debug = !__FILE__.match?("/opt/rbin/")

####################################################################################################
########################################## String Extensions #######################################
####################################################################################################
class String
  def indent(prefix = "  ")
    prefix + gsub("\n", "\n#{prefix}")
  end
end

####################################################################################################
########################################## Server Module ###########################################
####################################################################################################
module Servers
  ####################################################################################################
  #################################################### IO ############################################
  ####################################################################################################
  class MockIO
    def run_commands(*commands)
      commands.each { |command| puts "> #{command}" }

      true
    end

    def run_command(command)
      run_commands(command)
    end

    def command_output(command)
      puts "> #{command}"
      "fake_command_output"
    end

    def check_output(command, expected, debug_value = true)
      puts "# Checking output of '#{command}' expecting '#{expected}', using debug value #{debug_value}"
      debug_value
    end

    def write_file(pathname, string)
      puts "Writing to file #{pathname}\n#{string.indent("######  ")}"
    end

    def make_path(pathname)
      puts "Making path with parents #{pathname}"
    end

    def rbin_dir
      Pathname.new(__FILE__).parent.parent
    end

    def assets_path
      rbin_dir.join("assets")
    end
  end

  class IO
    class << self
      def instance
        $debug ? MockIO.new : new
      end
    end

    def run_commands(*commands)
      commands.each do |command|
        puts "> #{command}"
        return false unless system(command)
      end

      true
    end

    def run_command(command)
      run_commands(command)
    end

    def command_output(command)
      puts "> #{command}"
      `#{command}`
    end

    def check_output(command, expected)
      puts "# Checking output of command against:\n#{expected.indent(">>  ")}"
      command_output(command)
        .tap { |out| puts out.indent("<<  ") }
        .match?(expected)
    end

    def write_file(pathname, string)
      puts "Writing to file #{pathname}\n#{string.indent("######  ")}"
      pathname.write(string)
    end

    def make_path(pathname)
      puts "Making path with parents #{pathname}"
      pathname.mkpath
    end

    def rbin_dir
      Pathname.new("/opt/rbin")
    end

    def assets_path
      rbin_dir.join("assets")
    end
  end

  ####################################################################################################
  ########################################## Base Server #############################################
  ####################################################################################################
  class BaseServer
    attr_reader :name, :host_prefix, :io

    def initialize(name: nil, port: nil, host_prefix: nil)
      @name = name
      @port = port
      @host_prefix = host_prefix
      @io = IO.instance
    end

    def install
      puts "No-op install for server #{name} (#{host}:#{port})"
    end

    def uninstall
      puts "No-op install means no-op uninstall for server #{name} (#{host}:#{port})"
    end

    def start
      raise "Must implement start for server #{name}"
    end

    def backup
      puts "No backup implemented for server #{name}"
    end

    def nginx?
      puts "No nginx dependency for server #{name}"

      false
    end

    def host
      return "<no-host>" unless host_prefix
      "#{host_prefix}.hallhouse.link"
    end

    def port
      return "<no-port>" unless @port
      @port
    end
  end

  ####################################################################################################
  ########################################## Static Home Site ########################################
  ####################################################################################################
  class StaticHomesite < BaseServer
    def initialize
      super(name: "Static Homesite")
    end

    def install
      return if checksums_match?

      io.run_commands(
        "rm -rf #{dest_path}",
        "mkdir -p #{dest_path}",
        "cp -r #{source_path.join("build")}/* #{dest_path}",
        "systemctl restart nginx"
      )
    end

    def uninstall
      io.run_command("rm -rf #{dest_path}")
    end

    def start
      puts "Homesite start is managed by nginx"
    end

    def stop
      puts "Homesite is managed by nginx, nothing to stop"
    end

    private

    def checksums_match?
      source_checksum == dest_checksum
    end

    def source_checksum
      checksum(source_path)
    end

    def dest_checksum
      checksum(dest_path)
    end

    def source_path
      io.assets_path.join("static-homesite")
    end

    def dest_path
      Pathname.new("/var/hall-house/www/")
    end

    def checksum(path)
      io
        .command_output("find #{path} -type f | xargs cat | md5sum")
        .split
        .first
        .tap { |sum| puts "Checksum for #{path} is [#{sum}]" }
    end
  end

  ####################################################################################################
  ########################################## Pihole ##################################################
  ####################################################################################################
  class Pihole < BaseServer
    def initialize
      super(host_prefix: "pihole", port: 2080, name: "PiHole")
    end

    def nginx? = true

    def start
      update_port
      io.run_command("pihole restartdns")
    end

    def stop
      puts "Pihole start is automated by setup, nothing to stop, if you need to stop pihole, use:"
      puts "pihole stop"
    end

    def install
      return if installed?
      io.run_command("curl -sSL https://install.pi-hole.net | bash")
    end

    def uninstall
      puts "Please uninstall pihole manually with:"
      puts "pihole uninstall"
    end

    private

    def installed?
      io.run_command("which pihole")
    end

    def update_port
      io.write_file(config_path, config)
      start_or_restart_lighttpd
    end

    def start_or_restart_lighttpd
      return io.run_command("systemctl restart lighttpd") if lighttpd_running?

      io.run_command("systemctl start lighttpd")
    end

    def lighttpd_running?
      io.check_output("systemctl status lighttpd", "running")
    end

    def config
      <<~config
        server.port := #{port}
        setenv.add-environment = ( "VIRTUAL_HOST" => "#{host}" )
      config
    end

    def config_path
      Pathname.new("/etc/lighttpd/external.conf")
    end
  end

  ####################################################################################################
  ########################################## Baby Buddy ##############################################
  ####################################################################################################
  class BabyBuddy < BaseServer
    def initialize
      super(host_prefix: "baby", port: 3080, name: "BabyBuddy")
    end

    def nginx? = true

    def install
      make_directory
    end

    def uninstall
      puts "BabyBuddy is run using docker, you can remove it by killing the docker process"
    end

    def start
      stop if present?
      io.run_command(start_command)
    end

    def stop
      io.run_command(stop_command) if running?
      io.run_command(remove_command) if present?
    end

    def backup
      backup_task.run
    end

    private

    def running?
      io.check_output("docker ps", name.downcase)
    end

    def present?
      io.check_output("docker ps -a", name.downcase)
    end

    def make_directory
      io.make_path(appdata_directory)
    end

    def start_command
      <<~start
        docker run -d \
          --name=#{name.downcase} \
          -e PUID=1000 \
          -e PGID=1000 \
          -e TZ=America/New_York \
          -e CSRF_TRUSTED_ORIGINS=http://127.0.0.1:8000,https://#{host} \
          -p 3080:8000 \
          -v "#{appdata_directory}:/config" \
          --restart unless-stopped \
          lscr.io/linuxserver/babybuddy:latest
      start
    end

    def stop_command
      "docker kill #{name.downcase}"
    end

    def remove_command
      "docker container rm #{name.downcase}"
    end

    def backup_task
      Backup.new(path: directory, name: name.downcase)
    end

    def directory
      Pathname.new("/home/millerhall/var/#{name.downcase}")
    end

    def appdata_directory
      directory.join("appdata")
    end
  end

  ####################################################################################################
  ########################################## Nginx ###################################################
  ####################################################################################################
  class Nginx
    attr_reader :io

    def initialize
      @io = IO.instance
    end

    def install
      setup_network
      install_nginx
      place_config_file
      restart_nginx
    end

    def uninstall
      puts "Will not uninstall nginx"
    end

    private

    def setup_network
      return if network_setup?

      puts "Warning: This will reset the network to use IP 192.168.0.200, you will need to reconnect..."
      io.run_commands(
        "cp #{netplan_file} /etc/netplan/00-installer-config.yaml",
        "netplan apply"
      )
    end

    def install_nginx
      return if installed?

      io.run_commands("apt-get update", "apt-get install nginx -y")
    end

    def place_config_file
      io.write_file(config_destination, config)
    end

    def restart_nginx
      io.run_command("systemctl restart nginx")
    end

    def installed?
      io.run_command("which nginx")
    end

    def network_setup?
      io.check_output("hostname -I", "192.168.0.200")
    end

    def netplan_file
      io
        .rbin_dir
        .join("assets")
        .join("netplan")
        .join("home_server_netplan_installer")
    end

    def config_destination
      Pathname.new("/etc/nginx/nginx.conf")
    end

    def config
      ERB.new(config_erb).result(binding)
    end

    def config_erb
      io.rbin_dir.join("assets").join("nginx").join("home_server.erb").read
    end

    def servers
      Registry.servers
    end

    class << self
      def install
        new.install
      end
    end
  end

  ####################################################################################################
  ########################################## Backup ##################################################
  ####################################################################################################
  class Backup
    attr_reader :path, :name, :io

    def initialize(path:, name:)
      @path = path
      @name = name
      @io = IO.instance
    end

    def run
      puts "Backing up directory #{path}"
      copy_existing_backup
    end

    private

    def copy_existing_backup
      io.make_path(backup_path)
      io.run_command("mv #{new_backup} #{old_backup}")
      io.run_command("tar cf - #{path} | gzip - > #{new_backup}")
    end

    def backup_path
      Pathname.new("/var/backup/#{name}")
    end

    def old_backup
      backup_path.join("previous.tar.gz")
    end

    def new_backup
      backup_path.join("current.tar.gz")
    end
  end

  class Registry
    class << self
      def servers_for_args(args)
        args.empty? ? servers : args.map { |name| server(name) }
      end

      def servers
        [Pihole.new, StaticHomesite.new, BabyBuddy.new]
      end

      def server(name)
        server =
          servers.find do |server|
            /#{name.downcase}/.match? server.name.downcase
          end

        unless server
          puts "Unable to find server matching name '#{name}'"
          exit(1)
        end

        yield(server)
      end
    end
  end
end
