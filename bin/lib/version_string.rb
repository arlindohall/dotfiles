
class VersionString
  OPERATIONS = [
    GREATER_THAN_EQUAL = ">=",
    PESSIMISTIC_GREATER = "~>",
    GREATER_THAN = ">",
    LESS_THAN_EQUAL = "<=",
    PESSIMISTIC_LESS = "<~",
    LESS_THAN = "<",
    EQUAL = "=",
    NOT_EQUAL = "!=",
  ]

  class Comparison
    def valid_versions
      versions.select { |version| is_valid_version?(version) }
    end

    def versions
    end

    def is_valid_version?(version)
      raise NotImplementedError, "Subclass must implement #is_valid_version?"
    end
  end

  class Version
    attr_reader :engine, :major, :minor, :patch, :suffix
    def initialize(engine: nil, major: nil, minor: nil, patch: nil, suffix: nil)
      @engine = engine
      @major = major
      @minor = minor
      @patch = patch
      @suffix = suffix
    end
  end

  class VersionList
    def latest
      @versions.sort_by(&:patch)
        .sort_by(&:minor)
        .sort_by(&:major)
        .last
    end
  end

  class GreaterThanEqual < Comparison
    def valid_versions(available)
    end
  end

  class GreaterThan < Comparison
  end

  class PessimisticGreater < Comparison
  end

  class LessThanEqual < Comparison
  end

  class LessThan < Comparison
  end

  class PessimisticLess < Comparison
  end

  class Equal < Comparison
  end

  class NotEqual < Comparison
  end

  VERSION_MATCHERS = {
    GREATER_THAN_EQUAL => GreaterThanEqual,
    PESSIMISTIC_GREATER => PessimisticGreater,
    GREATER_THAN => GreaterThan,
    LESS_THAN_EQUAL => LessThanEqual,
    PESSIMISTIC_LESS => PessimisticLess,
    LESS_THAN => LessThan,
    EQUAL => Equal,
    NOT_EQUAL => NotEqual,
  }

  def initialize(string)
    @string = string
  end
end
