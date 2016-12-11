module AssDevel
  module Cycles
    module Application
      # @abstract
      class Abstract
        include Support::Logger
        attr_accessor :fixturies, :before_run, :after_run
        attr_reader :app_spec, :options
        def initialize(app_spec, **options)
          @app_spec = app_spec
          @options = options
          yield self if block_given?
        end

        def run
          before_run.execute(self) if before_run
          run_cycle
          after_run.execute(self) if after_run
        end

        def run_cycle
          fail 'Abstract method class'
        end
        private :run_cycle
      end

      class Design < Abstract
        attr_accessor :build_dir

        def src
          app_spec.src
        end

        def make_build
          src.make_build build
        end

        def build
          @build ||= AssDevel::Application::Builds::FileApp
            .new(:design, build_dir, **build_app_opts)
        end

        def run_cycle
          console "Build src: #{src.src_root}"
          make_build
          console "Connection srtring: '#{info_base.connection_string}'"
          open_designer
          build.dump_src
        end

        def console(m)
          puts m
        end

        def open_designer
          console "Wait while designer open ..."
          info_base.designer.run.wait.result.verify!
        end

        def info_base
          build.info_base
        end

        def build_app_opts
          r = {}
          r[:fixturies] if fixturies
          options.merge r
        end
        private :build_app_opts
      end

      class Testing < Abstract; end

      class Release < Abstract; end
    end
  end
end
