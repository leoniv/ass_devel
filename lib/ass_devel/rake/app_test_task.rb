module AssDevel
  module Rake
   require "rake/testtask"
   class AppTestTask < ::Rake::TestTask
      attr_accessor :work_cycle, :app_name

      def initialize(name = :test)
        super do |t|
          t.description = 'Run 1C application tests'\
            + (@name == :test ? "" : " for #{@name}")
          yield t if block_given?
        end
      end

      def make_app_build
        cs, pr = work_cycle.make_test_build
        ENV["#{app_name}_UNDER_TEST"] = cs
        ENV["#{app_name}_PLATFORM_REQUIRE"] = "= #{pv}"
      end

      def run_code
        make_app_build
        super
      end
    end
  end
end
