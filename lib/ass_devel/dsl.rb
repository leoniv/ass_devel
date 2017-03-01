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

    module Patch
      attr_reader :specification
      def patch(name, &block)
        spec = AssDevel::Patch::Specification.new
        spec.name = name
        spec.platform_require = self::PLATFORM_REQUIRE
        spec.src_root = self::SRC_ROOT
        spec.release_dir = self::RELEASE_DIR
        spec.base_name = self::BASE_NAME
        spec.base_version = self::BASE_VERSION
        spec.src_class = self::SRC_CLASS
        yield spec
        @specification = spec
      end
    end
  end
end
