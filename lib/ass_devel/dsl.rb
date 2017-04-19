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

    module External
      def _external(type_cls, &block)
        spec = AssDevel::External::Specification.new(type_cls)
        name_space = self.name.split('::')
        spec.name = name_space.pop
        spec.platform_require = self::PLATFORM_REQUIRE
        spec.src_root = self::SRC_ROOT
        spec.release_dir = self::RELEASE_DIR
        spec.name_space = eval(name_space.join('::')) || eval(spec.name)
        spec.object_module_template = self.object_module_template if\
          self.respond_to? :object_module_template
        yield spec
        @specification = spec
      end
      private :_external

      def dataprocessor(&block)
        _external(AssDevel::External::Specification::Types::Processor,
                  &block)
      end

      def report(&block)
        _external(AssDevel::External::Specification::Types::Report,
                  &block)
      end

      def specification
        @specification
      end
    end
  end
end
