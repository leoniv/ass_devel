module AssDevel
  module DSL
    module Application
      class Specification
        attr_accessor :name, :platform_require, :src_root

        def src
          @src ||= Sources::Application.new(src_root, self)
        end
        attr_accessor :Synonym
        attr_accessor :Comment
        attr_accessor :Version
        attr_accessor :Copyright
        attr_accessor :BriefInformation
        attr_accessor :DetailedInformation
        attr_accessor :ConfigurationInformationAddress
      end

      def application(name, &block)
        # FIXME: This is stub only
        spec = Specification.new
        spec.name = name
        spec.platform_require = self::PLATFORM_REQUIRE
        spec.src_root = self::SRC_ROOT
        yield spec
        @specification = spec
      end

      def specification
        @specification
      end
    end
  end
end
