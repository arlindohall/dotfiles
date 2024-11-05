# frozen_string_literal: true

class Object
  def debug(message)
    warn message
  end

  def output(message)
    $stdout.puts message
  end
end
