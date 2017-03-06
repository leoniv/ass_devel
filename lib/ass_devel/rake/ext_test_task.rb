module AssDevel
  module Rake
    require 'ass_devel/rake/app_test_task'
    class ExtTestTask < AppTestTask
      attr_accessor :app_template

      alias_method :ext_name, :app_name
      alias_method :ext_name=, :app_name=
      def make_app_build
        ext_path, cs, pv = work_cycle.make_test_build(app_template)
        ENV["#{ext_name}_UNDER_TEST"] = ext_path
        ENV["#{ext_name}_APPLICATION"] = cs.to_s
        ENV["#{ext_name}_PLATFORM_REQUIRE"] = "= #{pv}"
      end
    end
  end
end
