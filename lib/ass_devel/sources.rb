module AssDevel
  module Sources
    require 'fileutils'
    require 'diffy'

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

    module Abstract
      # @abstract
      class Src
        include Support::TmpPath
        include Support::Logger
        attr_reader :src_root
        alias_method :path, :src_root

        def initialize(src_root)
          fail ArgumentError, 'src_root must not be nil' if src_root.to_s.empty?
          @src_root = src_root
#          AssDevel::InfoBase.configure do |config|
#            config.platform_require = platform_require
#          end
          fail_if_repo_not_clear
        end

        def fail_if_repo_not_clear
          fail 'Repo not clear' unless repo_clear?
        end
        private :fail_if_repo_not_clear

#        def platform_require
#          fail 'Not specified platform_require' if\
#            owner.platform_require.to_s.empty?
#          owner.platform_require
#        end

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

        def repo_ls_tree
          handle_shell "git ls-tree -r HEAD #{src_root}"
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

        attr_reader :app_src
        def initialize(app_src)
          super app_src.src_root
          @app_src = app_src
        end

        def self.ROOT_FILE
          'Configuration.xml'
        end

        def dumper_version
          app_src.dumper_version
        end

        def src_root
          File.join(app_src.src_root, self.class.DIR)
        end

        def info_base
          app_src.info_base
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
            app_src.write_dumper_version(ib.thick.version)
            ib.cfg.dump_xml(src_root)
          end
          repo_add_to_index
        end
      end

      class ExternalObject < Src ; end
    end

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
  end
end
