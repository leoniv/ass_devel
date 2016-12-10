module AssDevel
  module Application
    # @todo it's stub
    class Specification
      attr_accessor :name, :platform_require, :src_root

      def src
        @src ||= Src.new(self)
      end
      attr_accessor :Synonym
      attr_accessor :Comment
      attr_accessor :Version
      attr_accessor :Copyright
      attr_accessor :BriefInformation
      attr_accessor :DetailedInformation
      attr_accessor :ConfigurationInformationAddress
    end

    class Src < Sources::Abstract::Src
      include Sources::DumperVersionWriter

      DEF_BUILD_DIR = './application.builds'


      attr_reader :info_base
      alias_method :ib, :info_base

      attr_reader :db_cfg_src, :cfg_src, :app_spec
      def initialize(app_spec)
        super app_spec.src_root
        @app_spec = app_spec
        @db_cfg_src = Sources::DbCfgSrc.new(self)
        @cfg_src = Sources::CfgSrc.new(self)
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
        Diffy::Diff.new(db_cfg_src.repo_ls_tree, cfg_src.repo_ls_tree)
      end

      def src_diff?
        db_cfg_src.repo_ls_tree != cfg_src.repo_ls_tree
      end
    end
  end
end
