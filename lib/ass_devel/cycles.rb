module AssDevel
  module Support
    # TODO: extract shell
    module Shell
      def self.handle_shell(cmd)
        out = `#{cmd} 2>&1`.strip
        fail out unless $?.success?
        out
      end

      def handle_shell(cmd)
        AssDevel::Support::Shell.handle_shell(cmd)
      end
    end
  end

  module Cycles
    class DifferentConfigError < StandardError; end
    class DifferentVersionError < StandardError; end
    class CheckConfigError < StandardError; end
    class DifferentAttributeErrror < StandardError; end

    module Mixins
      module Release
        include Support::Shell
        extend Support::Shell

        TAG_PREFIX = 'v'
        # Version must be a string like: 1.2.3.word.2.word.1.2
        # where first 3 segments is necessary and is a numbers
        # and all other is optional words in down case or numbers
        VERSION_PATTERN = '\d+\.\d+\.\d+((\.\d+)|(\.[a-z]+))*'

        VERSION_REGEX = %r{^#{VERSION_PATTERN}\z}
        VERSION_TAGS_REGEX = %r{^#{TAG_PREFIX}#{VERSION_PATTERN}\z}

        def self.version_tag(version)
          fail ArgumentError, "Invalid version string `#{version}'\n"\
          "Version must be a string like: `1.2.3.word.2.word.1.2'"\
          " where first 3 segments is necessary and is a numbers"\
          " and all other is optional words in down case or numbers" unless
          version.to_s =~ VERSION_REGEX

          "#{TAG_PREFIX}#{version}"
        end

        def self.versions
          version_tags.map do |str|
            str.gsub(%r{^#{TAG_PREFIX}},'')
          end.map {|str| Gem::Version.new(str)}.sort
        end

        def self.version_tags
          handle_shell('git tag').split("\n")
            .select {|t| t.strip =~ VERSION_TAGS_REGEX}
        end

        def version_tag
          Cycles::Mixins::Release.version_tag(app_version)
        end

        def guard_clear
          repo_clear? || fail('Repo doesn\'t clean!')
        end

        def repo_clear?
          repo_status.empty?
        end

        def repo_status
          handle_shell "git status -s"
        end

        def make_tag
          console "Make tag `#{version_tag}'"
          tag_version
        end

        def tag_version
          handle_shell "git tag -m \"Version #{app_version}\" #{version_tag}"
        end

        def tag_exist?
          self.class.version_tags.include?(version_tag)
        end

        def self.included(base)
          base.instance_eval do
            def versions
              Cycles::Mixins::Release.versions
            end

            def version_tags
              Cycles::Mixins::Release.version_tags
            end
          end
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
          fail 'Abstract method call'
        end

        def release
          check_rel_dir
          fail "Tag #{version_tag} exists" if tag_exist?
          binary_release
          commit_binary if respond_to? :commit_binary
          make_tag
          console "TODO: manually push commits and tags"
        end

        def before_release
          fail 'Abstract method call'
        end

        def after_release
          fail 'Abstract method call'
        end

        def run_cycle
          guard_clear
          before_release
          release
          after_release
        end

        def release_dir
          app_spec.release_dir || fail('Release dir require')
        end

        def binary_release
          @binary_release = binary_release_make
        end

        def check_rel_dir
          fail "#{release_dir} not exists or it doesn't directory" unless\
            File.directory?(release_dir)
        end

        def binary_release_make
          fail 'Abstract method call'
        end
      end

      module CommitBinary
        class RelfileUploder
          include Support::Shell

          attr_reader :cycle, :version, :base_path, :flatten
          def initialize(cycle, version, base_path, flatten = false)
            @cycle = cycle
            @version = Gem::Version.new(version)
            @base_path = base_path
            @flatten = flatten
          end

          def tag
           Cycles::Mixins::Release.version_tag(version.to_s)
          end

          def version_exist?
            cycle.class.versions.include? version
          end

          def upload
            FileUtils.mkdir_p(File.dirname(dest_file))
            fail "Rel #{tag} not exists" unless version_exist?
            sh("git show #{tag}:#{release_file} > #{dest_file}")
          end

          def release_file
            sh "git ls-tree --full-name --name-only #{tag} #{cycle.release_file}"
          end

          def dest_file
            File.join(base_path, fname)
          end

          def fname
            fail 'Abstract method call'
          end

          def sh(cmd)
            handle_shell(cmd)
          end
        end

        def commit_binary
          handle_shell "git add \"#{binary_release}\""
          handle_shell(
            "git commit -i \"#{binary_release}\" -m \"Release #{version_tag}\"")
        end

        def upload_release(version, base_path, flatten = false)
          fail 'Abstract method call'
        end

        def release_file
          fail 'Abstract method call'
        end
      end
    end

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

        def console(m)
          puts m
        end
      end

      class Design < Abstract
        attr_accessor :build_dir
        attr_accessor :bkup_data
        attr_accessor :bkup_path

        def make_test_build
          make_build
          [info_base.connection_string, build.platform_version]
        end

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
          rebuild
          open_designer
          dump_src
          clean_up
        end

        def dump_src
          console "Dump src: #{src.src_root}"
          build.dump_src
        end

        def clean_up
          if bkup_data
            console "Backup build to: #{info_base.send(:bkup_file, bkup_path)}"
            info_base.bkup_data bkup_path if bkup_data
          end
          rm_build
         end

        def rebuild
          rm_build
          console "Build src: #{src.src_root}"
          make_build
          console "Build connection srtring: '#{info_base.connection_string}'"
        end

        def rm_build
          if built?
            console "Remove existing build: #{info_base.connection_string}"
            info_base.rm! :yes if built?
          end
        end

        def built?
          build.spec = app_spec
          build.src = src
          build.built?
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
        class RelfileUploder < Mixins::CommitBinary::RelfileUploder
          DEST_FILE_NAME = '1Cv8.cf'
          attr_reader :cycle, :version, :base_path, :flatten

          def fname
            return "#{cycle.app_spec.name}.#{version}.cf" if flatten
            File.join(cycle.app_spec.name.to_s, version.to_s, DEST_FILE_NAME)
          end
        end

        include Mixins::Release
        include Mixins::CommitBinary

        REL_FILE_NAME = '1Cv8.cf.distrib'

        def cf_file
          File.join(release_dir, REL_FILE_NAME)
        end

        def release_file
          cf_file
        end

        def upload_release(version, base_path, flatten = false)
          RelfileUploder.new(self, version, base_path, flatten).upload
        end

        def before_release
          rebuild
          check_cf_diff
          check_spec
          check_config
        end

        def after_release
          # NOP
        end

        def build
          @build ||= AssDevel::Application::Builds::FileApp
            .new(:release, build_dir, **build_app_opts)
        end

        protected

        def check_cf_diff
          fail DifferentConfigError, 'Cfg and DbCfg are different' if src.src_diff?
        end

        def check_spec
          # TODO: check or testing app specification
          check_version
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

        def binary_release_make
          console "Build disribuition .cf file`#{version_tag}'"
          make_cf
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

    module Patch
      class Design < Application::Design
        def build
          @build ||= AssDevel::Patch::Builds::FileApp
            .new(:design, build_dir, **build_app_opts)
        end
      end

      class Release < Application::Release
        REL_FILE_NAME = '1Cv8.cf'
        def check_spec
          # TODO: check or testing app specification
          check_version
        end

        def check_version
          console 'Check version'
          fail 'FIXME'
#          fail DifferentVersionError,
#            "App version `#{app_version}'"\
#            " not match app_spec version `#{app_spec.version}'" unless\
#            app_version == app_spec.version
        end

        def cf_file
          File.join(release_dir, REL_FILE_NAME)
        end

        def make_cf
          cf_file_ = cf_file
          cmd = info_base.designer do
            fail 'FIXME'
#            createDistributionFiles do
#              cfFile cf_file_
#            end
          end
          cmd.run.wait.result.verify!
          cf_file_
        end
      end
    end

    module External
      module Abstract
        attr_accessor :build_dir
        attr_reader :app_template

        def full_win_path
          AssLauncher::Support::Platforms
            .path(build.build_path).realpath.win_string
        end

        def console(m)
          puts m
        end

        def run(app_template)
          @app_template = app_template
          super()
        end

        def info_base
          build.info_base
        end

        def clean_up
          rm_build
          rm_application
        end

        def rm_build
          if built?
            console "Remove existing build: #{build.build_path}"
            build.rm!
          end
        end

        def rm_application
          unless info_base.read_only?
            console "Remove existing application: #{info_base.connection_string}"
            info_base.rm! :yes
          end
        end

        def built?
          build.spec = spec
          build.src = src
          build.binary_built?
        end

        def src
          spec.src
        end

        def build
          @build ||= AssDevel::External::Builds::BinFile
            .new(app_template, cycle_name, build_dir, **options)
        end

        def cycle_name
          self.class.name.split('::').last.downcase.to_sym
        end

        def make_build
          make_application
          begin
            make_binary
          rescue
            rm_application
            raise
          end
        end

        def make_binary
          console "Build src: #{src.src_root}"
          src.make_build build
          console "Builded binary: '#{build.build_path}'"
        end

        def make_application
          console "Build application: #{info_base.connection_string}"
          info_base.make unless info_base.read_only?
        end

        def rebuild
          rm_build
          make_build
        end

        def self.included(base)
          base.send(:alias_method, :spec, :app_spec)
        end
      end

      class Design < Application::Abstract
        include Abstract

        def make_test_build(app_template)
          @app_template = app_template
          build.spec = spec
          build.src = src
          make_build
          [build.build_path,
           info_base.connection_string,
           build.platform_version]
        end

        def run_cycle
          rebuild
          open_designer
          dump_src
          clean_up
        end

        def open_designer
          console "Binary path for designer: #{full_win_path}"
          console "Wait while designer open ..."
          info_base.designer.run.wait.result.verify!
        end

        def dump_src
          console "Dump binary to: #{src.src_root}"
          src.dump
        end
      end

      class Release < Application::Abstract
        class RelfileUploder < Mixins::CommitBinary::RelfileUploder
          attr_reader :cycle, :version, :base_path, :flatten

          def fname
            return flatten_fname if flatten
            File.join(name_space, binary_fname)
          end

          def flatten_fname
            "#{flatten_name_space}.#{binary_fname}"
          end

          def binary_fname
            "#{cycle.spec.name}.#{version}.#{cycle.spec.type.ext}"
          end

          def flatten_name_space
            cycle.spec.name_space.name.gsub('::', '.')
          end

          def name_space
            cycle.spec.name_space.name.gsub('::', '/')
          end
        end
        include Abstract
        include Mixins::Release
        include Mixins::CommitBinary

        def app_version_get
          object_attributes[:version]
        end

        def object_attributes
          @object_attributes ||= object_attributes_get
        end

        def object_attributes_get
          result = {}
          begin
            ext = info_base.ole(:external)
            ext.__open__ info_base.connection_string
            eobject = external_object(ext)

            fail ArgumentError,
              'ExternalProcessor o ExternalReport must specify version'\
              ' like a function VERSION in object\'s module' unless\
              eobject.ole_respond_to? :VERSION
            fail ArgumentError,
              'ExternalProcessor o ExternalReport must specify namespace'\
              ' like a function NAMESPACE in object\'s module' unless\
              eobject.ole_respond_to? :NAMESPACE
            result[:version] = eobject.VERSION
            result[:name_space] = eobject.NAMESPACE
            result[:name] = eobject.Metadata.Name
          ensure
            ext.__close__ if ext
          end
          result
        end

        def ole_version(ole_connector)
           Gem::Version.new ole_connector.NewObject('SystemInfo').AppVersion
        end

        # @todo Fuckin 1C. Refactoring require
        def external_connect(ole_connector)
          dd = ole_connector.newObject('BinaryData', full_win_path)
          link = ole_connector.putToTempStorage(dd)

          if ole_version(ole_connector) > Gem::Version.new('8.3.9.2033')
            aod = ole_connector.newObject 'UnsafeOperationProtectionDescription'
            aod.UnsafeOperationWarnings = false
            ole_connector.send(ole_manager)
              .connect(link, external_name, false, aod)
          else
            ole_connector.send(ole_manager)
              .connect(link, external_name, false, aod)
          end
          external_name
        end

        def external_name
          app_spec.name
        end

        def external_object(ole_connector)
          ole_connector.send(ole_manager)
            .Create(external_connect(ole_connector))
        end

        def ole_manager
          spec.type.ole_manager
        end

        def before_release
          rebuild
          check_spec
        end

        def check_spec
          check(:name)
          check(:name_space)
          check_version
        end

        def check(what)
          console "Check #{what}"
          fail DifferentAttributeErrror,
            "Object #{what} `#{object_attributes[what]}'"\
            " not match app_spec #{what} `#{app_spec.send(what)}'" unless\
            object_attributes[what] == app_spec.send(what).to_s
        end

        def after_release
          clean_up
        end

        # Returns path to binary file in repo
        def binary_release_make
          console "Build release binary `#{version_tag}'"
          FileUtils.cp build.build_path, release_file
          release_file
        end

        def upload_release(version, base_path, flatten = false)
          RelfileUploder.new(self, version, base_path, flatten).upload
        end

        def release_file
          File.join(release_dir, "#{spec.name}.#{spec.type.ext}")
        end
      end
    end
  end
end
