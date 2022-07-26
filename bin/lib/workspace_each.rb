
require 'pathname'

class WorkspaceEach
  def initialize(path)
    @path = Pathname.new(path)
  end

  def act_git_repos
    @path.each_child do |child|
      if child.directory? && child.join('.git').exist?
        act(child)
      elsif child.directory?
        $stderr.puts "Error: #{child} is not a git repository"
      end
    end
  end

  def act(child)
    raise "Must implement #act for each subclass of WorkspaceEach"
  end

  def within_child(child, cmd)
    system <<~git_command
    cd #{child}
    #{cmd}
    git_command
  end

  def print_name(child)
    name = " #{child.basename.to_s} "
    padding = '-' * ((max_length - name.length) / 2)
    header = "#{padding}#{name}#{padding}"
    header = header + '-' if header.length.odd?
    puts "\n#{header}\n\n"
  end

  private

    def max_length
      @max_length ||= calculate_max_length
    end

    def calculate_max_length
      max = @path.each_child.map(&:basename).map(&:to_s).max_by(&:length).length + 12
      max >= 80 ? max : 80
    end
end
