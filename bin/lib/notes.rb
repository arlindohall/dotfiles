
require 'pathname'

class Notes
  class Flag
    def initialize(text)
      @text = text
    end

    def year
      date[0]
    end

    def month
      date[1]
    end

    def day
      date[2]
    end

    def file
      Pathname.new(Notes.notes_dir).join(@text.split(":").first)
    end

    def flag
      unnormalized_flag.downcase.gsub("-", "_")
    end

    def unnormalized_flag
      sentiment ? flag_part[1..] : flag_part
    end

    def sentiment
      case flag_part.chars.first
      when "-"
        :negative
      when "+"
        :positive
      end
    end

    private

    def date
      @text.scan(/(\d{4})\/(\d{2})(\d{2})/).flatten.map(&:to_i)
    end

    def flag_part
      @text.split(":").last.gsub(";", "")
    end
  end

  def self.flags
    new.flags
  end

  def self.notes_dir
    Pathname.new(ENV["HOME"]).join("var/notes/src")
  end

  def flags
    from_notes_dir do
      return parse_flags
    end
  end

  def parse_flags
    @parse_flags ||= `#{flags_grep_command}`
      .split("\n")
      .map { |flag| Flag.new(flag) }
      .group_by { |flag| flag.flag }
  end

  def from_notes_dir(&block)
    Dir.chdir(self.class.notes_dir, &block)
  end

  def flags_grep_command
    "rg -o ';[\\w-]+;'"
  end
end
