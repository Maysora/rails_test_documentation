module RailsTestDocumentation
  module Formatter
    class Base
      attr_accessor :dhash

      def initialize dhash
        self.dhash = dhash
      end

      def ext
        ''
      end

      def output_name
        ENV['TEST_DOCUMENTATION_NAME'].presence || 'STDOUT'
      end

      private

      def sort_tests tests
        tests.sort do |a,b|
          "#{test_sort_key(a[0])}_#{a}" <=> "#{test_sort_key(b[0])}_b"
        end
      end

      def test_sort_key key
        %w(GET POST PUT PATCH DELETE).index(key.split(' ', 2)[0]) || key
      end
    end
  end
end