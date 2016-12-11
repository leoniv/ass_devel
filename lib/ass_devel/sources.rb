module AssDevel
  module Sources
    require 'fileutils'

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

    module Builded
      def make_build(build)
        @build = build.build(self, spec)
      end

      attr_reader :build
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

        def repo_blobs
          repo_ls_tree.split("\n").each_with_object(Hash.new '') do |line, obj|
            line =~ %r{\A(\S+)\s+(\S+)\s+(?<sha>\S+)\s+(?<file>.*\z)}
            obj[sha] = file
          end
        end

        def repo_shas
          repo_blobs.keys.sort
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

      class ExternalObject < Src ; end
    end
  end
end
