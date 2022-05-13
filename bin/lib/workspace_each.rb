
require 'pathname'

class WorkspaceEach
  def initialize(path, &action)
    @path = Pathname.new(path)
    @action = action
  end

  def act_git_repos
    @path.each_child do |child|
      if child.directory? && child.join('.git').exist?
        @action.call child
      elsif child.directory?
        $stderr.puts "Error: #{child} is not a git repository"
      end
    end
  end
end
