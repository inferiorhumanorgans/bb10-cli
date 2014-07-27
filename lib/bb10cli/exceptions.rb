module Bb10Cli
  class Exceptions
    class OutputFormatNotImplementedError < NotImplementedError; end
    class AuthenticationError < Exception; end
    class InvalidAuthCookieError < AuthenticationError; end
  end
end
