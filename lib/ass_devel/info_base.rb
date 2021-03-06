module AssDevel
  require 'ass_maintainer/info_bases/test_info_base'
  require 'ass_maintainer/info_bases/tmp_info_base'

  class InfoBase < AssMaintainer::InfoBases::TestInfoBase
    class DbCfg < AssMaintainer::InfoBase::DbCfg
      include Support::TmpPath

      def tmp_ib
        @tmp_ib ||= AssMaintainer::InfoBases::TmpInfoBase
          .new platform_require: infobase.platform_require
      end
      private :tmp_ib

      def tmp_cf
        @tmp_cf ||= tmp_path('cf')
      end
      private :tmp_cf

      def dump_xml(path)
        tmp_ib.make
        tmp_ib.cfg.load(dump(tmp_cf))
        tmp_ib.cfg.dump_xml(path)
        path
      ensure
        FileUtils.rm_rf tmp_cf
        tmp_ib.rm!
      end
    end

    attr_reader :db_cfg_src, :cfg_src
    def initialize(name, connection_string, db_cfg_src, cfg_src = nil, **opts)
      @db_cfg_src = db_cfg_src
      @cfg_src = cfg_src
      super name, connection_string, false, **opts.merge(template: db_cfg_src)
    end

    def db_cfg
      @db_cfg ||= DbCfg.new(self) if exists?
    end

    def make
      fail_if_src_not_exists(db_cfg_src)
      super
    end

    def make_infobase!
      super
      load_cfg_src if src_diff?
      return self
    end
    private :make_infobase!

    def src_diff?
      return false if cfg_src.nil?
      db_cfg_src.repo_shas != cfg_src.repo_shas
    end

    def load_cfg_src
      fail_if_src_not_exists(cfg_src)
      return cfg.load cfg_src.src_root if File.file? cfg_src.src_root
      cfg.load_xml(cfg_src.src_root)
    end
    private :load_cfg_src

    def fail_if_src_not_exists(src)
      fail "#{src} not exists" unless src.exists?
    end
    private :fail_if_src_not_exists

    def thick
      @thick ||= super
    end

    def thin
      @thin ||= super
    end

    def bkup_data(dir = nil)
      fail ArgumentError, 'Dir require for server infobase' if\
        (dir.nil? && !is?(:file))
      dump bkup_file(dir)
    end

    def bkup_file(dir)
      return "#{connection_string.file}.bkup.dt" if dir.nil?
      return File.join(dir, "#{name}.bkup.dt")
    end
    private :bkup_file
  end
end
