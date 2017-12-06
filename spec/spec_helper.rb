require 'cocoapods'

module Pod
  # Overrides logging so it does not pollute the tests
  #
  module UI
    class << self
      def puts(message = '') end

      def print(message) end
    end
  end
end
