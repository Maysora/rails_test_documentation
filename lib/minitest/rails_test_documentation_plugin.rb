require_relative '../rails_test_documentation/minitest.rb'

module Minitest
  def self.plugin_rails_test_documentation_options(opts, options)
    if ENV['TEST_DOCUMENTATION_NAME'].present?
      options[:documentation] = true
      options[:documentation_format] ||= ENV['TEST_DOCUMENTATION_NAME'].scan(/\.(.+)$/).flatten.first || 'md'
    end

    opts.on "-D", "--documentation [FORMAT]", "Print documentation in specified format (text / md), default to md" do |format|
      options[:documentation] = true
      options[:documentation_format] = format || options[:documentation_format] || 'md'
    end
  end

  def self.plugin_rails_test_documentation_init(options)
    self.reporter << RailsTestDocumentation.new(options) if options[:documentation]
  end
end
