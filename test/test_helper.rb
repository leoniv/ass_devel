$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'ass_devel'

require 'minitest/autorun'
require 'mocha/mini_test'

module AssDevelTest
  module AssertItAbstract
    def assert_it_abstract(object, method, *args)
      e = proc {
        object.send(method, *args)
      }.must_raise RuntimeError
      e.message.must_match %r{abstract method}i
    end
  end

  PLATFORM_REQUIRE = '~> 8.3.9.0'
  module Fixtures
    PATH = File.expand_path('../fixtures', __FILE__)
    IB_XML_SRC = File.join PATH, 'ib_xml_src'
    fail unless File.directory? IB_XML_SRC
  end
end
