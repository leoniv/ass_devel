module AssDevel
  require 'ass_tests/info_bases/info_base'
  class TmpInfoBase < AssTests::InfoBases::InfoBase
    include Support::TmpPath

    # Make new tmp infoabse and yield it in block
    # after block executing remove tmp infobase
    def self.make_rm(template = nil, **options, &block)
      fail 'Block require' unless block_given?
      ib = new(template, **options)
      ib.make
      begin
        yield ib
      ensure
        ib.rm!
      end
    end

    def initialize(template = nil, **opts)
      super *new_ib_args,
        **opts.merge(template: template)
    end

    def rm!(*_)
      super :yes
    end

    def new_ib_args
      [tmp_ib_name, self.class.cs_file(file: tmp_ib_path), false]
    end

    def tmp_ib_name
      @tmp_ib_name ||= File.basename(tmp_path('ib')).gsub('-','_')
    end

    def tmp_ib_path
      @tmp_ib_path ||= File.join(Dir.tmpdir, tmp_ib_name)
    end
  end

  class InfoBase < AssTests::InfoBases::InfoBase
    class DbCfg < AssMaintainer::InfoBase::DbCfg
      include Support::TmpPath

      def tmp_ib
        @tmp_ib ||= TmpInfoBase.new platform_require: infobase.platform_require
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
      load_cfg_src if cfg_src
      return self
    end
    private :make_infobase!

    def load_cfg_src
      fail_if_src_not_exists(cfg_src)
      cfg.load_xml(cfg_src.src_root)
    end

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
