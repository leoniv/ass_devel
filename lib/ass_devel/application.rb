module AssDevel
  module Application
    # @todo it's stub
    class Specification
      attr_accessor :name, :platform_require, :src_root

      def src
        @src ||= Src.new(self)
      end
      attr_accessor :Name
      alias_method :name, :Name
      alias_method :name=, :Name=
      attr_accessor :Synonym
      attr_accessor :Comment
      attr_accessor :Version
      alias_method :version, :Version
      attr_accessor :Copyright
      attr_accessor :BriefInformation
      attr_accessor :DetailedInformation
      attr_accessor :ConfigurationInformationAddress
    end

    class Src < Sources::Abstract::Src
      include Sources::DumperVersionWriter
      include Sources::Builded

      attr_reader :db_cfg_src, :cfg_src, :app_spec
      alias_method :spec, :app_spec
      def initialize(app_spec)
        super app_spec.src_root
        @app_spec = app_spec
        @db_cfg_src = Sources::DbCfgSrc.new(self)
        @cfg_src = Sources::CfgSrc.new(self)
      end

      def dump(build)
        fail 'Repo not clear' unless repo_clear?
        write_dumper_version build.platform_version
        cfg_src.dump(build)
        db_cfg_src.dump(build)
        repo_add_to_index
      end

      def init_src
        FileUtils.mkdir_p src_root
        db_cfg_src.init_src unless db_cfg_src.exists?
        cfg_src.init_src unless cfg_src.exists?
        repo_add_to_index
      end

      def src_diff
        Diffy::Diff.new(db_cfg_src.repo_ls_tree, cfg_src.repo_ls_tree)
      end

      def src_diff?
        db_cfg_src.repo_ls_tree != cfg_src.repo_ls_tree
      end
    end
  end
end
