require 'test_helper'
module AssDevelTest
  describe AssDevel::Application::Src::Abstract::CfgSrc do
    include AssertItAbstract

    def inst_stub(app_src = nil)
      @inst_stub ||= Class.new(AssDevel::Application::Src::Abstract::CfgSrc) do
        def initialize(app_src)
          @app_src = app_src
        end
      end.new(app_src)
    end

    it '.ROOT_FILE' do
      AssDevel::Application::Src::CfgSrc.ROOT_FILE
        .must_equal 'Configuration.xml'
    end

    it '#root_file' do
      inst_stub.expects(:src_root).returns('src_root')
      inst_stub.root_file.must_equal "src_root/#{self.class.desc.ROOT_FILE}"
    end

    it '#dumper_version' do
      app_src = mock
      app_src.expects(:dumper_version).returns(:dumper_version)
      inst_stub(app_src).dumper_version.must_equal :dumper_version
    end

    it '#src_root' do
      app_src = mock
      app_src.expects(:src_root).returns('app_src_src_root')
      inst_stub(app_src).class.expects(:DIR).returns('dir')
      inst_stub.src_root.must_equal 'app_src_src_root/dir'
    end

    it '#dump_' do
      assert_it_abstract inst_stub, :dump_, :build
    end

    it '#dump' do
      seq = sequence('dump')
      inst_stub.expects(:exists?).in_sequence(seq).returns(true)
      inst_stub.expects(:rm_rf!).in_sequence(seq)
      inst_stub.expects(:dump_).with(:build).in_sequence(seq)
      inst_stub.expects(:repo_add_to_index).in_sequence(seq).returns(:add_index)
      inst_stub.dump(:build).must_equal :add_index
    end

    it '#dump fail if not exists' do
      inst_stub.expects(:exists?).returns(false)
      e = proc {
        inst_stub.dump(:build)
      }.must_raise RuntimeError
      e.message.must_match %r{Src root not exists}i
    end

    it '#init_src fail if exists?' do
      inst_stub.expects(:exists?).returns(true)
      e = proc {
        inst_stub.init_src
      }.must_raise RuntimeError
      e.message.must_match %r{Src exists}
    end

    it '#init_src' do
      seq = sequence('init_src')
      thick = mock
      thick.expects(:version).returns(:dumper_version)
      cfg = mock
      ib = mock
      ib.expects(:thick).returns(thick)
      ib.expects(:cfg).returns(cfg)

      app_src = mock

      inst_stub(app_src).expects(:exists?).in_sequence(seq).returns(false)
      inst_stub.expects(:platform_require).in_sequence(seq).returns('42')
      AssDevel::TmpInfoBase.expects(:make_rm)
        .in_sequence(seq).with(platform_require: '42').yields(ib)
      inst_stub.expects(:src_root).in_sequence(seq).returns(:src_root)
      FileUtils.expects(:mkdir_p).in_sequence(seq).with(:src_root)
      app_src.expects(:write_dumper_version).with(:dumper_version)
        .in_sequence(seq)
      inst_stub.expects(:src_root).in_sequence(seq).returns(:src_root)
      cfg.expects(:dump_xml).in_sequence(seq).with(:src_root)
      inst_stub.expects(:repo_add_to_index).returns(:add_index)

      inst_stub.init_src.must_equal :add_index
    end
  end

  describe AssDevel::Application::Src::DbCfgSrc do
    def inst_stub
      @inst_stub ||= Class.new(AssDevel::Application::Src::DbCfgSrc) do
        def initialize

        end
      end.new
    end

    it '.DIR' do
      inst_stub.class.DIR.must_equal 'db_cfg.src'
    end

    it '#dump_' do
      build = mock
      info_base = mock
      db_cfg = mock

      build.expects(:info_base).returns(info_base)
      info_base.expects(:db_cfg).returns(db_cfg)
      db_cfg.expects(:dump_xml).with(:src_root).returns(:dump_)

      inst_stub.expects(:src_root).returns(:src_root)
      inst_stub.send(:dump_, build).must_equal :dump_
    end
  end

  describe AssDevel::Application::Src::CfgSrc do
    def inst_stub
      @inst_stub ||= Class.new(AssDevel::Application::Src::CfgSrc) do
        def initialize

        end
      end.new
    end

    it '.DIR' do
      inst_stub.class.DIR.must_equal 'cfg.src'
    end

    it '#dump_' do
      build = mock
      info_base = mock
      cfg = mock

      build.expects(:info_base).returns(info_base)
      info_base.expects(:cfg).returns(cfg)
      cfg.expects(:dump_xml).with(:src_root).returns(:dump_)

      inst_stub.expects(:src_root).returns(:src_root)
      inst_stub.send(:dump_, build).must_equal :dump_
    end
  end

  describe AssDevel::Application::Src do
    def inst_stub(db_cfg_src = nil, cfg_src = nil)
      @inst_stub ||= Class.new AssDevel::Application::Src do
        def initialize(db_cfg_src, cfg_src)
          @db_cfg_src = db_cfg_src
          @cfg_src = cfg_src
        end
      end.new(db_cfg_src, cfg_src)
    end

    def app_spec_stub
      Class.new AssDevel::Application::Specification do
        def initialize

        end
      end.new
    end

    it '#initialize' do
      app_spec = mock
      app_spec.responds_like app_spec_stub
      app_spec.expects(:src_root).returns('src_root')
      src = AssDevel::Application::Src.new(app_spec)
      src.src_root.must_equal 'src_root'
      src.app_spec.must_equal app_spec
      src.db_cfg_src.must_be_instance_of AssDevel::Application::Src::DbCfgSrc
      src.cfg_src.must_be_instance_of AssDevel::Application::Src::CfgSrc
    end

    it '#init_src' do
      seq = sequence('init_src')
      inst_stub(mock, mock).expects(:src_root).in_sequence(seq).returns(:src_root)
      FileUtils.expects(:mkdir_p).in_sequence(seq).with :src_root
      inst_stub.db_cfg_src.expects(:exists?).in_sequence(seq).returns(false)
      inst_stub.db_cfg_src.expects(:init_src).in_sequence(seq)
      inst_stub.cfg_src.expects(:exists?).in_sequence(seq).returns(false)
      inst_stub.cfg_src.expects(:init_src).in_sequence(seq)
      inst_stub.expects(:repo_add_to_index).in_sequence(seq).returns(:ok)
      inst_stub.init_src.must_equal :ok
    end

    it '#dump' do
      seq = sequence('dump')
      build = mock
      build.responds_like AssDevel::Application::Builds::FileApp.new
      build.expects(:src).returns(inst_stub(mock, mock))
      build.expects(:platform_version).returns(:version)
      inst_stub(mock, mock).expects(:repo_clear?).returns(true)
      inst_stub.expects(:write_dumper_version).in_sequence(seq).with(:version)
      inst_stub.cfg_src.expects(:dump).with(build).in_sequence(seq)
      inst_stub.db_cfg_src.expects(:dump).with(build).in_sequence(seq)
      inst_stub.expects(:repo_add_to_index).in_sequence(seq).returns(:ok)
      inst_stub.dump(build).must_equal :ok
    end

    it '#dump fail if not clear' do
      inst_stub.expects(:repo_clear?).returns(false)
      e = proc {
        inst_stub.dump(nil)
      }.must_raise RuntimeError
      e.message.must_equal 'Repo not clear'
    end

    it '#dump fail if invalid build' do
      build = mock src: 'other src'
      inst_stub.expects(:repo_clear?).returns(true)
      e = proc {
        inst_stub.dump(build)
      }.must_raise RuntimeError
      e.message.must_equal 'Invalid build'
    end

    it '#src_diff' do
      cfg_src = mock
      cfg_src.expects(:repo_ls_tree).returns('1 ls tree')
      cfg_src.expects(:repo_ls_tree).returns('2 ls tree')
      inst_stub.expects(:db_cfg_src).returns(cfg_src)
      inst_stub.expects(:cfg_src).returns(cfg_src)
      diff = inst_stub.src_diff
      diff.must_be_instance_of Diffy::Diff
    end

    it '#src_diff? false' do
      cfg_src = mock
      cfg_src.expects(:repo_ls_tree).returns('ls tree').twice
      inst_stub.expects(:db_cfg_src).returns(cfg_src)
      inst_stub.expects(:cfg_src).returns(cfg_src)
      inst_stub.src_diff?.must_equal false
    end

    it '#src_diff true' do
      cfg_src = mock
      cfg_src.expects(:repo_ls_tree).returns('1 ls tree')
      cfg_src.expects(:repo_ls_tree).returns('2 ls tree')
      inst_stub.expects(:db_cfg_src).returns(cfg_src)
      inst_stub.expects(:cfg_src).returns(cfg_src)
      inst_stub.src_diff?.must_equal true
    end
  end

  describe AssDevel::Application::Builds::AppBuild do
    include AssertItAbstract

    def inst
      @inst ||= Class.new do
        include AssDevel::Application::Builds::AppBuild
      end.new
    end

    it '#conn_str' do
      assert_it_abstract inst, :conn_str
    end

    it '#info_base' do
      inst.expects(:new_infobase).returns(:new_infobase).once
      inst.info_base.must_equal :new_infobase
      inst.info_base.must_equal :new_infobase
    end

    def app_spec_stub
      Class.new AssDevel::Application::Specification do
        def initialize

        end
      end.new
    end

    it '#new_infobase' do
      spec = mock
      spec.responds_like app_spec_stub
      spec.expects(:platform_require).returns :platform_require
      inst.expects(:spec).returns(spec)

      app_src = mock
      app_src.responds_like app_src_stub
      app_src.expects(:db_cfg_src).returns(:db_cfg_src)
      app_src.expects(:cfg_src).returns(:cfg_src)
      inst.expects(:src).returns(app_src).twice

      inst.expects(:name).returns(:name)
      inst.expects(:conn_str).returns(:conn_str)
      inst.expects(:options).returns({opt1: 1})

      seq = sequence('new_infobase')

      AssDevel::InfoBase.config
        .expects(:platform_require=)
        .in_sequence(seq)
        .with(:platform_require)
      AssDevel::InfoBase.expects(:new)
        .in_sequence(seq)
        .with(:name, :conn_str, :db_cfg_src, :cfg_src, opt1: 1)
        .returns(:new_infobase)
      inst.new_infobase.must_equal :new_infobase
    end

    it '#platform_version' do
      ib = mock
      thick = mock
      ib.expects(:thick).returns(thick)
      thick.expects(:version).returns(:version)
      inst.expects(:info_base).returns(ib)
      inst.platform_version.must_equal :version
    end

    it '#dump_src fail' do
      inst.expects(:built?).returns(false)
      e = proc {
        inst.dump_src
      }.must_raise RuntimeError
      e.message.must_equal 'It not built'
    end

    def app_src_stub
      Class.new AssDevel::Application::Src do
        def initialize

        end
      end.new
    end

    it '#dump_src' do
      src = mock
      src.responds_like app_src_stub
      src.expects(:dump).with(inst).returns(:ok)
      inst.expects(:built?).returns(true)
      inst.expects(:src).returns(src)
      inst.dump_src.must_equal :ok
    end
  end

  describe AssDevel::Application::Builds::FileApp do
    def inst(key = :key, dir = :dir, **options)
      @inst ||= self.class.desc.new(key, dir, **options)
    end

    it 'include AppBuild' do
      self.class.desc.include?(AssDevel::Application::Builds::AppBuild)
        .must_equal true
    end

    it '#options' do
      inst(opt: 1).options.must_equal(opt: 1)
    end

    it '#ext' do
      inst.ext.must_equal 'ib'
    end

    it '#dir' do
      inst.dir.must_equal :dir
      inst.dir = nil
      inst.dir.must_equal './application.builds'
    end

    it '#conn_str' do
      inst.expects(:build_path).returns(Tmp::BUILD_DIR)
      inst.send(:conn_str).is.must_equal :file
    end

    it '#build_ if built?' do
      inst.expects(:built?).returns(true)
      inst.expects(:info_base).never
      inst.build_.must_equal inst
    end

    it '#build_' do
      info_base = mock
      seq = sequence('build_')
      inst.class.superclass.any_instance.expects(:build_).in_sequence(seq)
      inst.expects(:info_base).returns(info_base)
      info_base.expects(:make).in_sequence(seq)
      inst.expects(:built?).returns(false)
      inst.expects(:info_base).never
      inst.build_.must_equal inst
    end

    it '#built? true' do
      ib = mock
      inst.expects(:info_base).returns(ib).twice
      ib.expects(:exists?).returns(true)
      inst.built?.must_equal true
    end

    it '#built? false' do
      ib = mock
      inst.expects(:info_base).returns(ib).twice
      ib.expects(:exists?).returns(false)
      inst.built?.must_equal false
    end

    it '#built? false' do
      inst.expects(:info_base).returns(nil).once
      inst.built?.must_equal false
    end
  end
end
