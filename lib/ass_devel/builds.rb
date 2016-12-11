module AssDevel
  module Builds
    module Abstract
      # @abstract
      class Build
        attr_reader :key, :options
        attr_accessor :src, :spec
        def initialize(key, **options)
          @key = key
          @options = options
        end

        def build(src, spec)
          self.src = src
          self.spec = spec
          build_
        end

        def build_
          fail 'Abstract method call'
          self
        end
        private :build_

        def name
          fail 'Abstract method call'
        end

        def version
          spec.version
        end

        def revision
          src.revision
        end

        def built?
          fail 'Abstract method call'
        end
      end

      # @abstract
      class FileBuild < Build
        attr_accessor :dir
        def initialize(key = nil, dir = nil, **options)
          super key, **options
          @dir = dir
        end

        def build_
          FileUtils.mkdir_p dir
        end

        def name
          r = "#{spec.name}"
          r << ".#{key}" if key
          r << ".#{version}.#{revision}.#{ext}"
        end

        # Build name extension
        def ext
          fail 'Abstract method call'
        end

        def build_path
          File.join(dir, name)
        end
      end
    end
  end
end
