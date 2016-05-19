module RailsTestDocumentation
  module Formatter
    class Markdown < Base
      attr_accessor :dhash, :urls, :output, :menu, :content

      def initialize dhash
        self.dhash = dhash
        self.urls = {}
        self.menu = self.content = ''
      end

      def ext
        '.md'
      end

      def output_name
        if ENV['TEST_DOCUMENTATION_NAME'].present?
          "#{ENV['TEST_DOCUMENTATION_NAME'].sub(/\..+$/, '')}#{ext}"
        else
          'STDOUT'
        end
      end

      def print
        urls = {}
        self.output = ENV['TEST_DOCUMENTATION_NAME'].present? ?
                        File.open(output_name, 'wt') :
                        STDOUT

        dhash.sort.each do |class_name, result|
          class_url = "\##{format_url(class_name)}"
          self.menu += "* [#{class_name}](#{class_url})\n"
          self.content += "\# #{class_name}\n\n"
          class_description = result.delete(:description)
          if class_description.present?
            self.content += "```\n#{class_description.delete(:text)}\n```\n\n---\n\n" if class_description[:text].present?
            class_description.each do |k,v|
              self.content += "#{'#' * 5} #{k.to_s.titleize}\n\n"
              self.content += print_description(v) + "\n\n"
            end
          end

          sort_tests(result).each do |test_name, arr|
            self.menu += "  * [#{test_name}](\##{format_url(test_name)})\n"
            self.content += "#{'#' * 2} #{test_name}\n\n"
            arr.group_by{|a| a[:response_status]}.sort.each do |status, data_arr|
              self.menu += "    * [#{status}](\##{format_url(status)})\n"
              self.content += "#{'#' * 3} #{status}\n\n"
              sort_samples(data_arr).each_with_index do |data, i|
                self.content += "---\n\n" unless i.zero?
                self.content += "#{'#' * 4} Sample #{i+1}\n\n"
                self.content += "```\n#{data[:description].delete(:text)}\n```\n\n---\n\n"
                data[:description].each do |k,v|
                  self.content += "#{'#' * 5} #{k.to_s.titleize}\n\n"
                  self.content += print_description(v) + "\n\n"
                end
                self.content += "__URL :__ #{data[:request_method]} `#{data[:request_path]}`\n\n"
                if data[:request_params].present?
                  self.content += "#{'#' * 5} Params\n\n"
                  self.content += "```json\n#{JSON.pretty_generate(Rack::Utils.parse_nested_query(data[:request_params].to_query))}\n```\n\n"
                end
                if data[:response_body].present?
                  self.content += "#{'#' * 5} Response\n\n"
                  response_format = response_format(data[:response_content_type])
                  data[:response_body] = JSON.pretty_generate(JSON.parse(data[:response_body])) if response_format == 'json'
                  self.content += "```#{response_format}\n#{data[:response_body]}\n```\n\n"
                end
              end
              self.content += "Go to: [class](#{class_url}) | [navigation](#navigation)\n\n"
            end
          end
        end

        output.puts "Generated using `rails test --documentation md`"
        output.puts
        output.puts '# Navigation'
        output.puts
        output.puts menu
        output.puts
        output.puts content
        output.close if ENV['TEST_DOCUMENTATION_NAME'].present?
      end

      private

      def format_url url
        url = url.to_s.gsub(/(:|&|\/|,|\(|\))/, '').parameterize
        if urls[url].present?
          new_url = url + "-#{urls[url]}"
          urls[url] += 1
          url = new_url
        else
          urls[url] = 1
        end
        url
      end

      def response_format content_type
        case content_type
        when /json/
          'json'
        when /xml/
          'xml'
        when /html/
          'html'
        else
          nil
        end
      end

      def print_description description
        if description.is_a? Array
          description.map{|d| "- #{d}" }.join("\n")
        elsif description.is_a? Hash
          description.map{|k,v| "- __#{k} :__ #{v}" }.join("\n")
        else
          description.to_s
        end
      end
    end
  end
end