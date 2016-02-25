Dir[File.join(File.dirname(__FILE__), 'formatters', '*.rb')].each {|file| require file }

module Minitest
  class RailsTestDocumentation < AbstractReporter
    attr_accessor :format, :dhash

    def initialize options
      self.format = options[:documentation_format]
      self.dhash = {}
    end

    def record(result)
      return if !result.is_a?(ActionController::TestCase) ||
                  !result.request.env['action_dispatch.request.path_parameters'] ||
                  no_documentation?(result)

      klass_name = result.class.name.gsub(/ControllerTest$/, '').titleize
      dhash[klass_name] ||= {}
      dhash[klass_name][:description] ||= process_description(result.instance_variable_get(:@test_class_description))
      content = {}

      content[:description] = process_description(result.instance_variable_get(:@test_description).presence || result.name.gsub('test_', '').humanize)
      content[:request_path] = result.request.path
      content[:request_method] = result.request.method
      content[:request_path_spec] = get_route_spec(result.request)
      if (params = result.request.env["action_dispatch.request.query_parameters"].presence || result.request.env["action_dispatch.request.request_parameters"]).present?
        content[:request_params] = params
      end
      content[:response_body] = result.response.body
      content[:response_status] = result.response.status
      content[:response_content_type] = result.response.header["Content-Type"]

      test_name = "#{result.request.method} #{content[:request_path_spec]}"
      dhash[klass_name][test_name] ||= []
      dhash[klass_name][test_name] << content
    rescue => e
      puts "Exception raised in test documentation: #{e}"
    end

    def report
      return unless passed?

      formatter = nil
      if format == 'md'
        formatter = ::RailsTestDocumentation::Formatter::Markdown.new dhash
      # elsif format == 'html'
      #   formatter = ::RailsTestDocumentation::Formatter::HTML.new dhash
      else
        # TODO: text format
      end
      return unless formatter
      puts "\nPrinting #{format} format to #{formatter.output_name}"
      formatter.print
    end

    private

    def get_route_spec request
      path = request.env['action_dispatch.request.path_parameters']
      ::Rails.application.routes.routes.find_all{|r| r.defaults.to_a.present? && (r.defaults.except(:format).to_a - path.to_a).empty?}.last.path.spec.to_s.gsub('(.:format)', '')
    end

    def process_description description
      if description.is_a? String
        padding = description.scan(/^\n +/).first
        description.gsub!(padding, "\n") if padding
        { text: description }
      else
        description
      end
    end

    def no_documentation?(result)
      no_doc = result.instance_variable_get(:@test_no_documentation)
      if no_doc.is_a? Array
        no_doc.include?(format)
      else
        !!no_doc
      end
    end
  end
end