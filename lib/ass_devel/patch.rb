module AssDevel
  # Patch of vendor Application
  # @todo
  module Patch
    class Specification
      attr_accessor :name, :platform_require, :src_root, :release_dir, :version,
        :base_name, :base_version

      # Expectetd {AssDevel::Sources::Xml AssDevel::Sources::Diff
      #  AssDevel::Sources::BinCf}
      attr_accessor :src_class

      def src
        @src ||= src_get
      end

      def src_get
        return src_class.new(self)
      end
      private :src_get
    end

    module Sources
      class Xml < Application::Src; end

      class Diff
        def initialize
          fail NotImplementedError
        end
      end

      class BinCf < Application::Src
        module Abstract
          require 'ass_maintainer/info_bases/tmp_info_base'
          class CfgSrc < Application::Src::Abstract::CfgSrc
            def init_src
              fail 'Src exists' if exists?
              AssMaintainer::InfoBases::TmpInfoBase
                .make_rm platform_require: platform_require do |ib|
                dump_ ib
              end
              repo_add_to_index
            end

            def dump_(build)
              return dump_cfg_ build if build.is_a? AssMaintainer::InfoBase
              dump_cfg_ build.info_base
            end

            def dump_cfg_(ib)
              fail 'Abstract method'
            end

            def to_s
              src_root
            end
          end
        end

        # @api private
        class DbCfgSrc < Abstract::CfgSrc
          def self.DIR
            'db_cfg.cf'
          end

          def dump_cfg_(ib)
            ib.db_cfg.dump src_root
          end
          private :dump_
        end

        # @api private
        class CfgSrc < Abstract::CfgSrc
          def self.DIR
            'cfg.cf'
          end

          # @api private
          def dump_cfg_(ib)
            ib.cfg.dump src_root
          end
          private :dump_
        end

        def initialize(app_spec)
          super app_spec, DbCfgSrc, CfgSrc
        end
      end
    end

    module Builds
      class FileApp < Application::Builds::FileApp
        DEF_DIR = 'patch.builds'

        def dir
          @dir || DEF_DIR
        end
      end
    end
  end
end
