require_relative '../rails_test_documentation/minitest.rb'

module Minitest
  def self.plugin_rails_test_documentation_options(opts, options)
    opts.on "--documentation FORMAT", "Print documentation in specified format (text / md)" do |format|
      options[:documentation] = true
      options[:documentation_format] = format
    end
  end

  def self.plugin_rails_test_documentation_init(options)
    self.reporter << RailsTestDocumentation.new(options) if options[:documentation]
  end
end
