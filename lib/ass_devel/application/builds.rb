module AssDevel
  module Application
    module Builds
      # @abstract
      module AppBuild
        def info_base
          @info_base ||= new_infobase
        end

        def new_infobase
          InfoBase.config.platform_require = spec.platform_require
          InfoBase.new(name, conn_str, src.db_cfg_src, src.cfg_src, **options)
        end

        def conn_str
          fail 'Abstract method call'
        end

        def platform_version
          info_base.thick.version
        end

        def dump_src
          fail 'It not built' unless built?
          src.dump(self)
        end
      end

      class FileApp < AssDevel::Builds::Abstract::FileBuild
        include AppBuild
        EXT = 'ib'
        DEF_DIR = './application.builds'

        def ext
          EXT
        end

        def dir
          @dir || DEF_DIR
        end

        def build_
          return self if built?
          super
          info_base.make
          self
        end

        def built?
          !info_base.nil? && info_base.exists?
        end

        def conn_str
          InfoBase.cs_file file: build_path
        end
        private :conn_str
      end

      class SrvApp < AssDevel::Builds::Abstract::Build
        include AppBuild
        def build_
          return self if built?
          info_base.make
          self
        end
      end

      class CfFile < AssDevel::Builds::Abstract::FileBuild
        def build_
          fail NotImplemetedError
        end
      end

      class CfuFile < AssDevel::Builds::Abstract::FileBuild
        def build_
          fail NotImplemetedError
        end
      end
    end
  end
end
