module AssDevel
  require 'ass_devel/meta_data/const'
  module Application
    ROLE_ADMIN = :Admin
    ROLE_ALL_RIGHTS = :AllRights
    ROLE_USER = :User
    ROLE_EXECUTOR = :ExternalExecute

    ROLES_DEFAULT = [ROLE_ADMIN, ROLE_ALL_RIGHTS]

    # @todo it's stub
    class Specification
      attr_accessor :name, :platform_require, :src_root, :release_dir

      def src
        @src ||= Src.new(self)
      end

      MetaData::Const::MdClasses.get(:Configuration).properties.each do |prop|
        attr_accessor prop.en
      end

      MetaData::Const::MdClasses.get(:Configuration)
        .collection_properties.each do |prop|
        attr_accessor prop.en
      end

      attr_writer :role_all_rights
      attr_writer :role_user
      attr_writer :role_admin
      attr_writer :role_executor

      def role_admin
        @role_admin ||= ROLE_ADMIN
      end

      def role_all_rights
        @role_all_rights ||= ROLE_ALL_RIGHTS
      end

      def role_user
        @role_user ||= ROLE_USER
      end

      def role_executor
        @role_executor ||= ROLE_EXECUTOR
      end

      def DefaultRoles
        @DefaultRoles ||= ROLES_DEFAULT
      end

      alias_method :name, :Name
      alias_method :name=, :Name=
      alias_method :version, :Version
    end

    class Src < Sources::Abstract::Src
      include Sources::DumperVersionWriter
      include Sources::Builded

      module Abstract
        # @api private
        class CfgSrc < Sources::Abstract::Src
          include Sources::HaveRootFile

          attr_reader :app_src
          def initialize(app_src)
            @app_src = app_src
            super app_src.src_root
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

          def dump(build)
            fail 'Src root not exists' unless exists?
            rm_rf!
            dump_(build)
            repo_add_to_index
          end

          def dump_(_build)
            fail 'Abstract method call'
          end

          def platform_require
            app_src.platform_require
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
      end

      # @api private
      class DbCfgSrc < Abstract::CfgSrc
        def self.DIR
          'db_cfg.src'
        end

        def dump_(build)
          build.info_base.db_cfg.dump_xml src_root
        end
        private :dump_
      end

      # @api private
      class CfgSrc < Abstract::CfgSrc
        def self.DIR
          'cfg.src'
        end

        # @api private
        def dump_(build)
          build.info_base.cfg.dump_xml src_root
        end
        private :dump_
      end

      attr_reader :db_cfg_src, :cfg_src, :app_spec
      alias_method :spec, :app_spec
      def initialize(app_spec, db_cfg_class = nil, cfg_class = nil)
        super app_spec.src_root
        @app_spec = app_spec
        @db_cfg_src = (db_cfg_class || DbCfgSrc).new(self)
        @cfg_src = (cfg_class || CfgSrc).new(self)
      end

      def platform_require
        app_spec.platform_require
      end

      def dump
        fail_if_repo_not_clear
        fail 'Invalid build' unless build
        write_dumper_version build.platform_version
        cfg_src.dump(build)
        db_cfg_src.dump(build)
        repo_add_to_index
      end

      def fail_if_repo_not_clear
        fail 'Repo not clear' unless repo_clear?
      end

      def init_src
        FileUtils.mkdir_p src_root
        db_cfg_src.init_src unless db_cfg_src.exists?
        cfg_src.init_src unless cfg_src.exists?
        repo_add_to_index
      end

      def src_diff
        fail NotImplementedError
      end

      def src_diff?
        db_cfg_src.repo_shas != cfg_src.repo_shas
      end
    end

    require 'ass_devel/application/builds'
  end
end
