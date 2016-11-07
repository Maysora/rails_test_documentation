module RailsTestDocumentation
  module Formatter
    class MarkdownMultiple < Base
      attr_accessor :dhash, :urls

      def initialize dhash
        self.dhash = dhash
      end

      def ext
        '.md'
      end

      def output_name
        if ENV['TEST_DOCUMENTATION_NAME'].present?
          "#{ENV['TEST_DOCUMENTATION_NAME'].sub(/\..+$/, '')}#{ext}"
        else
          'rails_documentation.md'
        end
      end

      def dir_name
        output_name.sub(/\..+$/, '')
      end

      def print
        main_output = File.open(output_name, 'wt')
        FileUtils.remove_dir dir_name if File.directory?(dir_name)
        FileUtils.mkdir_p dir_name

        main_output.puts "Generated using `rails test --documentation mdm`"
        main_output.puts
        main_output.puts '# Tests'
        main_output.puts

        dhash.sort.each do |class_name, result|
          self.urls = {}
          class_output_name = format_output_name(class_name)
          class_url = format_file_url(class_output_name, dir_name)
          main_output.puts "* [#{class_name}](#{class_url})"

          class_output = File.open(class_url, 'wt')
          begin
            class_output.puts "\# #{class_name}\n"

            class_description = result.delete(:description)
            if class_description.present?
              text = class_description.delete(:text)
              if text.present?
                main_output.puts "  * #{text}"
                class_output.puts "```\n#{text}\n```\n\n---\n"
              end
              class_description.each do |k,v|
                class_output.puts "#{'#' * 5} #{k.to_s.titleize}\n"
                class_output.puts print_description(v)
                class_output.puts
              end
            end

            content = ""
            class_output.puts '# Tests'
            sort_tests(result).each do |test_name, arr|
              class_output.puts "  * [#{test_name}](\##{format_url(test_name)})"
              content += "#{'#' * 2} #{test_name}\n\n"
              arr.group_by{|a| a[:response_status]}.sort.each do |status, data_arr|
                class_output.puts "    * [#{status}](\##{format_url(status)})"
                content += "#{'#' * 3} #{status}\n\n"
                sort_samples(data_arr).each_with_index do |data, i|
                  content += "---\n\n" unless i.zero?
                  content += "#{'#' * 4} Sample #{i+1}\n\n"
                  content += "```\n#{data[:description].delete(:text)}\n```\n\n---\n\n"
                  data[:description].each do |k,v|
                    content += "#{'#' * 5} #{k.to_s.titleize}\n\n"
                    content += print_description(v) + "\n\n"
                  end
                  content += "__URL :__ #{data[:request_method]} `#{data[:request_path]}`\n\n"
                  if data[:request_params].present?
                    content += "#{'#' * 5} Params\n\n"
                    content += "```json\n#{JSON.pretty_generate(Rack::Utils.parse_nested_query(data[:request_params].to_query))}\n```\n\n"
                  end
                  if data[:response_body].present?
                    content += "#{'#' * 5} Response\n\n"
                    response_format = response_format(data[:response_content_type])
                    data[:response_body] = JSON.pretty_generate(JSON.parse(data[:response_body])) if response_format == 'json'
                    content += "```#{response_format}\n#{data[:response_body]}\n```\n\n"
                  end
                end
                content += "Go to: [class](#tests) | [home](../#{output_name})\n\n"
              end
            end
            class_output.puts
            class_output.puts content
          ensure
            class_output.close
          end
        end
      ensure
        main_output.close
      end

      private

      def format_output_name name
        name = File.basename(name).downcase
        name = name.gsub(/(:|&|\/|,|\(|\))/,"_")
        name = "_#{name}" if name =~ /\A\.+\z/
        "#{name}#{ext}"
      end

      def format_file_url output_name, dir_name
        File.join(dir_name, output_name)
      end

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