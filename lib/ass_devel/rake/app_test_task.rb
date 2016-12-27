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

      def app_connection_string
        work_cycle.info_base.connection_string.to_s
      end

      def app_platform_require
        "= #{work_cycle.build.platform_version}"
      end

      def make_app_build
        work_cycle.make_build
        ENV["#{app_name}_UNDER_TEST"] = app_connection_string
        ENV["#{app_name}_PLATFORM_REQUIRE"] = app_platform_require
      end

      def run_code
        make_app_build
        super
      end
    end
  end
end
