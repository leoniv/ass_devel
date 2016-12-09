module AssDevel
  module Sources
    require 'fileutils'

    module Abstract
      # Mixin for reade and write dumper version
      module DumperVersionWriter
        def read_dumper_version
          File.read(dumper_version_file)
        end

        def dumper_version_file
          File.join(src_root, '.dumper_version')
        end

        def write_dumper_version(version)
          FileUtils.touch dumper_version_file
          f = File.open(dumper_version_file, 'w')
          f.write(version.to_s)
          f.close
        end
      end

      module HaveRootFile
        def root_file
          File.join(src_root, self.class.ROOT_FILE)
        end
      end

      # @abstract
      class Src
        include Support::TmpPath
        include Support::Logger
        attr_reader :src_root, :owner
        alias_method :path, :src_root

        def initialize(src_root, owner)
          fail ArgumentError, 'src_root must not be nil' if src_root.to_s.empty?
          @src_root = src_root
          @owner = owner
          AssDevel::InfoBase.configure do |config|
            config.platform_require = platform_require
          end
          fail_if_repo_not_clear
        end

        def fail_if_repo_not_clear
          fail 'Repo not clear' unless repo_clear?
        end
        private :fail_if_repo_not_clear

        def platform_require
          fail 'Not specified platform_require' if\
            owner.platform_require.to_s.empty?
          owner.platform_require
        end

        def dumper_version
          fail 'Abstract method call'
        end

        def dump(*_)
          fail 'Abstract method call'
        end

        def exists?
          File.exists?(src_root)
        end

        def revision
          handle_shell "git log --pretty=format:'%h' -n 1 #{src_root}"
        end

        def repo_clear?
          repo_status.empty?
        end

        def repo_status
          handle_shell "git status -s #{src_root}"
        end

        def repo_add_to_index
          handle_shell "git add #{src_root}"
        end

        def rm_rf!
          fail_if_repo_not_clear
          FileUtils.rm_rf Dir.glob(File.join(src_root, '*'))
        end

        def handle_shell(cmd)
          out = `#{cmd} 2>&1`.strip
          fail out unless $?.success?
          out
        end

        def init_src
          fail 'Abstract method call'
        end
      end

      class CfgSrc < Src
        include HaveRootFile

        def self.ROOT_FILE
          'Configuration.xml'
        end

        def dumper_version
          owner.dumper_version
        end

        def src_root
          File.join(owner.src_root, self.class.DIR)
        end

        def info_base
          owner.info_base
        end
        alias_method :ib, :info_base

        def dump
          fail 'Src root not exists' unless exists?
          rm_rf!
          dump_
          repo_add_to_index
        end

        def dump_
          fail 'Abstract method call'
        end

        def init_src
          fail 'Src exists' if exists?
          TmpInfoBase.make_rm platform_require: platform_require do |ib|
            FileUtils.mkdir_p src_root
            owner.write_dumper_version(ib.thick.version)
            ib.cfg.dump_xml(src_root)
          end
          repo_add_to_index
        end
      end

      class ExternalObject < Src ; end
    end

    class Application < Abstract::Src
      include Abstract::DumperVersionWriter

      DEF_BUILD_DIR = './application.builds'

      class DbCfgSrc < Abstract::CfgSrc

        def self.DIR
          'db_cfg.src'
        end

        def dump_
          info_base.db_cfg.dump_xml src_root
        end
        private :dump_
      end

      class CfgSrc < Abstract::CfgSrc
        def self.DIR
          'cfg.src'
        end

        def dump_
          info_base.cfg.dump_xml src_root
        end
        private :dump_
      end

      attr_reader :info_base
      alias_method :ib, :info_base

      attr_reader :db_cfg_src, :cfg_src
      def initialize(src_root, owner)
        super src_root, owner
        @db_cfg_src = DbCfgSrc.new(src_root, self)
        @cfg_src = CfgSrc.new(src_root, self)
      end

      def dump
        fail 'Call #build_*_app before #dump' unless app_built?
        write_dumper_version ib.thick.version
        cfg_src.dump
        db_cfg_src.dump
        repo_add_to_index
      end

      # Returns InfoBase
      def build_file_app(build_dir = DEF_BUILD_DIR,
                         build_name = def_build_name('ib'), **opts)
        fail_if_built
        FileUtils.mkdir_p build_dir
        new_file_info_base(build_dir, build_name, **opts).make
      end

      def new_file_info_base(bd, bn, **opts)
        @info_base ||=\
          InfoBase.new(bn, file_cs(bd, bn), db_cfg_src, cfg_src, **opts)
      end
      private :new_file_info_base

      def fail_if_built
        fail 'InfoBase already build' if app_built?
      end
      private :fail_if_built

      def app_built?
        info_base && info_base.exists?
      end

      def build_srv_app(*args)
        fail NotImplemetedError
        fail_if_built
      end

      def file_cs(path, name)
        InfoBase.cs_file file: build_path(path, name)
      end
      private :file_cs

      def def_build_name(ext)
        "#{owner.name}.#{owner.Version}.#{revision}.#{ext}"
      end
      private :def_build_name

      def build_path(dir, name = nil)
        File.join(dir, name)
      end
      private :build_path

      def init_src
        FileUtils.mkdir_p src_root
        db_cfg_src.init_src unless db_cfg_src.exists?
        cfg_src.init_src unless cfg_src.exists?
        repo_add_to_index
      end

      def src_diff
        fail NotImplemetedError
      end

      def src_diff?
        fail NotImplemetedError
      end
    end
  end
end
