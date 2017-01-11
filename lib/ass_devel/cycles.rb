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

      class Release < Design
        # @api private
        class RelfileUploder
          REL_FILE_NAME = '1Cv8.cf'
          attr_reader :cycle, :version, :base_path, :flatten
          def initialize(cycle, version, base_path, flatten = false)
            @cycle = cycle
            @version = Gem::Version.new(version)
            @base_path = base_path
            @flatten = flatten
          end

          def tag
            cycle.class.version_tag(version.to_s)
          end

          def version_exist?
            cycle.class.versions.include? version
          end

          def upload
            fail "Rel #{tag} not exists" unless version_exist?
            sh("git show #{tag}:#{src_cf_file} > #{dest_cf_file}")
          end

          def src_cf_file
            cycle.cf_file
          end

          def dest_cf_file
            FileUtils.mkdir_p(File.dirname(dest_path()))
          end

          def dest_path
            File.join(base_path, fname)
          end

          def fname
            return "#{cycle.app_spec.name}.#{version}.cf" if flatten
            File.join(cycle.app_spec.name, version.to_s, REL_FILE_NAME)
          end

          def sh(cmd)
            cycle.handle_shell(cmd)
          end
        end

        TAG_PREFIX = 'v'
        REL_FILE_NAME = '1Cv8.cf.distrib'
        class DifferentConfigError < StandardError; end
        class DifferentVersionError < StandardError; end
        class CheckConfigError < StandardError; end

        def self.version_tag(version)
          "#{TAG_PREFIX}#{version}"
        end

        def self.versions
          version_tags.map do |str|
            str.gsub(%r{^#{TAG_PREFIX}},'')
          end.map {|str| Gem::Version.new(str)}.sort
        end

        def self.version_tags
          handle_shell('git tag').split("\n")
            .select {|t| t.strip =~ %r{^#{TAG_PREFIX}\d+\.\d+\.\d+\.\d+\z}}
        end

        # TODO: extract shell
        def self.handle_shell(cmd)
          out = `#{cmd} 2>&1`.strip
          fail out unless $?.success?
          out
        end

        def cf_file
          File.join(release_dir, REL_FILE_NAME)
        end

        def release_dir
          app_spec.release_dir || fail('Release dir require')
        end

        def upload_release(version, base_path, flatten = false)
          RelfileUploder.new(self, version, base_path, flatten).upload
        end

        def run_cycle
          guard_clear
          console "Build src: #{src.src_root}"
          rebuild
          console "Connection srtring: '#{info_base.connection_string}'"
          check_cf_diff
          check_spec
          check_config
          release
        end

        def rebuild
          info_base.rm! :yes if built?
          make_build
        end

        def built?
          build.spec = app_spec
          build.src = src
          build.built?
        end

        def build
          @build ||= AssDevel::Application::Builds::FileApp
            .new(:release, build_dir, **build_app_opts)
        end

        protected

        def guard_clear
          repo_clear? || fail('Repo doesn\'t clean!')
        end

        def check_cf_diff
          fail DifferentConfigError, 'Cfg and DbCfg are different' if src.src_diff?
        end

        def check_spec
          # TODO: check or testing app specification
          check_version
        end

        def check_version
          console 'Check version'
          fail DifferentVersionError,
            "App version `#{app_version}'"\
            " not match app_spec version `#{app_spec.version}'" unless\
            app_version == app_spec.version
        end

        def app_version
          @app_version ||= app_version_get
        end

        def app_version_get
          begin
            ext = info_base.ole(:external)
            ext.__open__ info_base.connection_string
            result = ext.Metadata.Version
          ensure
            ext.__close__ if ext
          end
          result
        end

        def check_config
          console 'Check config'
          cmd = info_base.designer do
            checkConfig do
              _ConfigLogIntegrity
              _IncorrectReferences
              _ThinClient
              _WebClient
              _Server
              _ExternalConnection
              _ExternalConnectionServer
              _ThickClientManagedApplication
              _ThickClientServerManagedApplication
              _ThickClientOrdinaryApplication
              _ThickClientServerOrdinaryApplication
              _DistributiveModules
              _UnreferenceProcedures
              _HandlersExistence
              _EmptyHandlers
              _ExtendedModulesCheck
              _MobileAppClient
              _MobileAppServer
              _CheckUseModality
              _UnsupportedFunctional
              _AllExtensions
            end
          end
          ph = cmd.run.wait
          fail CheckConfigError, ph.result.assout unless ph.result.success?
        end

        def version_tag
          self.class.version_tag(app_version)
        end

        def tag_version
          handle_shell "git tag -m \"Version #{app_version}\" #{version_tag}"
        end

        def tag_exist?
          return false unless\
            self.class.version_tags.include?(version_tag)
          true
        end

        def commit_cf(cf)
          handle_shell "git add \"#{cf}\""
          handle_shell "git commit -i \"#{cf}\" -m \"Release #{version_tag}\""
        end

        def release
          fail "Tag #{version_tag} exists" if tag_exist?
          build_cf
          make_tag
          console "TODO: manually push commits and tags"
        end

        def make_tag
          console "Make tag `#{version_tag}'"
          tag_version
        end

        def check_rel_dir
          fail "#{release_dir} not exists or it doesn't directory" unless\
            File.directory?(release_dir)
        end

        def build_cf
          check_rel_dir
          console "Build disribuition .cf file`#{version_tag}'"
          commit_cf make_cf
        end

        def make_cf
          cf_file_ = cf_file
          cmd = info_base.designer do
            createDistributionFiles do
              cfFile cf_file_
            end
          end
          cmd.run.wait.result.verify!
          cf_file_
        end

        def handle_shell(cmd)
          self.class.handle_shell(cmd)
        end

        def repo_clear?
          repo_status.empty?
        end

        def repo_status
          handle_shell "git status -s"
        end
      end

      class Distribution < Abstract
        attr_writer :version
        attr_accessor :build_dir
        attr_accessor :demo_fixtures
        attr_accessor :attached_files

        def version
          @version || fail(ArgumentError, 'Version require')
        end

        def run_cycle
          fail NotImplementedError
        end
      end
    end
  end
end
