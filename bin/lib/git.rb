
module Git
  class BranchException < StandardError; end

  class ArgParser
    def initialize(argv)
      @argv = argv

      parse!
    end

    def interactive?
      (!!@args[:interactive]).tap { |v| debug("-- Interactive mode: #{v}") }
    end

    private

    def parse!
      @args = {}

      until @argv.empty?
        arg = @argv.shift
        case arg
        when '-i', '--interactive'
          @args[:interactive] = true
        else
          raise "Unknown argument: #{arg}"
        end
      end
    end
  end

  class Command
    class << self
      def call
        new.call
      end
    end

    def initialize
      @main_branch = main_branch
      @original_branch = original_branch

      set_arguments(Git::ArgParser.new(ARGV))
    end

    def call
      raise NotImplementedError, "Git Commands must implement the call method"
    end

    private

    def pull_main
      switch_to_main && command("git pull")
    end

    def pull_main_with_prune
      switch_to_main && command("git pull --prune")
    end

    def switch_to_main
      command("git switch #{@main_branch}")
    end

    def rebase_over_main
      if @interactive
        switch_to_current && command("git rebase -i #{@main_branch}")
      else
        switch_to_current && command("git rebase #{@main_branch}")
      end
    end

    def switch_to_current
      command("git switch #{@original_branch}")
    end

    def delete_current_branch
      command("git branch -d #{@original_branch}")
    end

    def command(cmd)
      debug("-- Running: #{cmd}")
      system(cmd)
    end

    def main_branch
      case `git branch`
      when /main/
        'main'
      when /master/
        'master'
      else
        raise BranchException, "Cannot find main branch"
      end
    end

    def original_branch
      `git branch --show-current`.chomp
    end

    def set_arguments(args)
      @interactive = args.interactive?
    end
  end
end
