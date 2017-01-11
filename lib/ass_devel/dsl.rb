module AssDevel
  module DSL
    module Application
      def application(name, &block)
        # FIXME: This is stub only
        spec = AssDevel::Application::Specification.new
        spec.name = name
        spec.platform_require = self::PLATFORM_REQUIRE
        spec.src_root = self::SRC_ROOT
        spec.release_dir = self::RELEASE_DIR
        yield spec
        @specification = spec
      end

      def specification
        @specification
      end
    end
  end
end
