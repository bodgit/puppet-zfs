RSpec.configure do |c|
  c.mock_with :rspec
end

require 'puppetlabs_spec_helper/module_spec_helper'
require 'rspec-puppet-facts'

unless RUBY_VERSION =~ /^1\.8/
  require 'simplecov'
  require 'coveralls'
end

include RspecPuppetFacts

RSpec.configure do |c|
  c.default_facts = { :augeasversion => '0.10.0' }
end

dir = Pathname.new(__FILE__).parent

Puppet[:modulepath] = File.join(dir, 'fixtures', 'modules')
Puppet[:libdir] = File.join(Puppet[:modulepath], 'stdlib', 'lib')

at_exit { RSpec::Puppet::Coverage.report! }

unless RUBY_VERSION =~ /^1\.8/
  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
  ]
  SimpleCov.start do
    add_filter 'spec/'
  end
end
