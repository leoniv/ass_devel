module AssDevel
  module Cycles
    module App
      # @abstract
      class Abstract
        include Support::Logger
        attr_accessor :fixturies, :before_run, :after_run
        attr_writer :build_dir
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

        def build_dir
          @build_dir || './builds'
        end

        def build_name
          fail 'Abstract method call'
        end
      end

      class Design < Abstract
        def src
          app_spec.src
        end

        def run_cycle
          open_designer
          src.dump
        end

        def console(m)
          puts m
        end

        def open_designer
          console "Build src: #{src.path}"
          console "Connection srtring: '#{info_base.connection_string}'"
          console "Wait while designer open ..."
          info_base.designer.run.wait.result.verify!
        end

        def info_base
          @info_base ||= src.build_file_app(build_dir, **build_app_opts)
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
