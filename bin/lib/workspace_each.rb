# frozen_string_literal: true
# typed: true

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
        warn "Error: #{child} is not a git repository"
      end
    end
  end

  def act(_child)
    raise 'Must implement #act for each subclass of WorkspaceEach'
  end

  def within_child(child, cmd)
    system <<~GIT_COMMAND
      cd #{child}
      #{cmd}
    GIT_COMMAND
  end

  def print_name(child)
    name = " #{child.basename} "
    padding = '-' * ((max_length - name.length) / 2)
    header = "#{padding}#{name}#{padding}"
    header += '-' if header.length.odd?
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
