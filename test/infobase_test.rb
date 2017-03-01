require 'test_helper'

module AssDevelTest
  describe AssDevel::TmpInfoBase do
    it '.new withot template' do
      ib = AssDevel::TmpInfoBase.new
      ib.must_be_instance_of AssDevel::TmpInfoBase
      ib.is?(:file).must_equal true
      ib.name.must_equal ib.tmp_ib_name
      assert_nil ib.template
      ib.connection_string.file.must_match %r{\A#{Dir.tmpdir}/#{ib.name}}
      ib.read_only?.must_equal false
      ib.exists?.must_equal false
    end

    it '.new template' do
      ib = AssDevel::TmpInfoBase.new(:template)
      ib.must_be_instance_of AssDevel::TmpInfoBase
      ib.is?(:file).must_equal true
      ib.name.must_equal ib.tmp_ib_name
      ib.template.must_equal :template
      ib.connection_string.file.must_match %r{\A#{Dir.tmpdir}/#{ib.name}}
      ib.read_only?.must_equal false
      ib.exists?.must_equal false
    end

    it '#make smoky' do
      ib = AssDevel::TmpInfoBase.new
      begin
        ib.make
        ib.exists?.must_equal true
      ensure
        ib.rm! if ib.exists?
      end
    end

    it '#make smoky with tempalte' do
      ib = AssDevel::TmpInfoBase.new(Fixtures::IB_XML_SRC)
      begin
        ib.make
        ib.exists?.must_equal true
        ib.template_loaded?.must_equal true
      ensure
        ib.rm! if ib.exists?
      end
    end

    it '.make_rm fail withot block' do
      e = proc {
        AssDevel::TmpInfoBase.make_rm
      }.must_raise RuntimeError
      e.message.must_equal 'Block require'
    end

    it '.make_rm' do
      seq = sequence('make_rm')
      ib = mock
      AssDevel::TmpInfoBase.expects(:new).with(:template, opt1: 1).returns(ib)
      ib.expects(:make).in_sequence(seq)
      ib.expects(:touch).in_sequence(seq)
      ib.expects(:rm!).in_sequence(seq)

      AssDevel::TmpInfoBase.make_rm(:template, opt1: 1) do |ib_|
        ib_.must_equal ib
        ib.touch
      end
    end
  end

  describe AssDevel::InfoBase do
    def src_stub
      AssDevel::Sources::Abstract::Src
        .any_instance.expects(:fail_if_repo_not_clear)
      src = mock
      src.responds_like AssDevel::Sources::Abstract::Src
        .new('src_root')
      src
    end

    def inst(**opts)
      cs = 'File="./tmp/tmp.ib"'
      @inst ||= AssDevel::InfoBase.new('name', cs, :db_cfg_src, :cfg_src)
    end

    it '#initialize' do
      inst.template.must_equal :db_cfg_src
    end

    it '#initialize for superclass mocked' do
      AssTests::InfoBases::InfoBase.any_instance.expects(:initialize)
        .with(:name, :conn_str, false, **{opt1: 1, template: :db_cfg_src})
        .returns(:new_ib)
      ib = AssDevel::InfoBase
        .new(:name, :conn_str, :db_cfg_src, :cfg_src, opt1: 1)
      ib.db_cfg_src.must_equal :db_cfg_src
      ib.cfg_src.must_equal :cfg_src
    end

    it '#make mocked' do
      AssTests::InfoBases::InfoBase.any_instance.expects(:make).returns(:ib)
      inst.expects(:fail_if_src_not_exists).with(:db_cfg_src)
      inst.make.must_equal :ib
    end

    it '#make_infobase! if src_diff? moked' do
      seq = sequence('make')
      AssTests::InfoBases::InfoBase.any_instance.expects(:make_infobase!)
        .in_sequence(seq).returns(:ib)
      inst.expects(:src_diff?).in_sequence(seq).returns true
      inst.expects(:load_cfg_src).in_sequence(seq)
      inst.send(:make_infobase!).must_equal inst
    end

    it '#make_infobase! unless src_diff? moked' do
      seq = sequence('make')
      AssTests::InfoBases::InfoBase.any_instance.expects(:make_infobase!)
        .in_sequence(seq).returns(:ib)
      inst.expects(:src_diff?).in_sequence(seq).returns false
      inst.expects(:load_cfg_src).never
      inst.send(:make_infobase!).must_equal inst
    end

    it '#src_diff? true' do
      cfg_src = mock
      cfg_src.expects :repo_shas => '1'
      cfg_src.expects :repo_shas => '2'
      inst.expects(:db_cfg_src).returns(cfg_src)
      inst.expects(:cfg_src).returns(cfg_src).twice
      inst.src_diff?.must_equal true
    end

    it '#src_diff? false' do
      cfg_src = stub :repo_shas => '1'
      inst.expects(:db_cfg_src).returns(cfg_src)
      inst.expects(:cfg_src).returns(cfg_src).twice
      inst.src_diff?.must_equal false
    end

    it '#src_diff? false if cfg_src.nil?' do
      inst.expects(:cfg_src).returns(nil)
      inst.expects(:db_cfg_src).never
      inst.src_diff?.must_equal false
    end

    it '#fail_if_src_not_exists fail' do
      src = mock
      src.expects(:exists?).returns(false)
      e = proc {
        inst.send(:fail_if_src_not_exists, src)
      }.must_raise RuntimeError
      e.message.must_match %r{not exists\z}
    end

    it '#fail_if_src_not_exists not fail' do
      src = mock
      src.expects(:exists?).returns(true)
      inst.send(:fail_if_src_not_exists, src)
    end

    it '#load_cfg_src with xml files src' do
      cfg_src = mock
      cfg_src.expects(:src_root).returns(:cfg_src).twice
      cfg = mock
      inst.expects(:fail_if_src_not_exists).with(cfg_src)
      inst.expects(:cfg).returns(cfg)
      inst.expects(:cfg_src).returns(cfg_src).at_least_once
      File.expects(:file?).with(:cfg_src).returns false
      cfg.expects(:load_xml).with(:cfg_src).returns(:ok)
      inst.send(:load_cfg_src).must_equal(:ok)
    end

    it '#load_cfg_src with binary file' do
      cfg_src = mock
      cfg_src.expects(:src_root).returns(:cfg_src).twice
      cfg = mock
      inst.expects(:fail_if_src_not_exists).with(cfg_src)
      inst.expects(:cfg).returns(cfg)
      inst.expects(:cfg_src).returns(cfg_src).at_least_once
      File.expects(:file?).with(:cfg_src).returns true
      cfg.expects(:load).with(:cfg_src).returns(:ok)
      cfg.expects(:load_xml).never
      inst.send(:load_cfg_src).must_equal(:ok)
    end

    it '#thick' do
      inst.thick.must_equal inst.thick
    end

    it '#thin' do
      inst.thin.must_equal inst.thin
    end

    it '#bkup_data' do
      inst.expects(:dump).with(inst.send :bkup_file, nil)
      inst.bkup_data
    end

    it '#bkup_data fail if #dir.nil? and #is? :server' do
      inst.expects(:is?).with(:file).returns(false)
      e = proc {
        inst.bkup_data nil
      }.must_raise ArgumentError
      e.message.must_equal 'Dir require for server infobase'
    end

    it '#bkup_file dir = ./tmp' do
      inst.send(:bkup_file, './tmp')
        .must_equal "./tmp/#{inst.name}.bkup.dt"
    end

    it '#bkup_file dir = nil' do
      inst.send(:bkup_file, nil)
        .must_equal "#{inst.connection_string.file}.bkup.dt"
    end

    include AssDevel::Support::TmpPath
    it 'InfoBase_make_smoky' do
      def src_mock(repo_shas)
        src = mock
        src.responds_like(src_stub)
        src.expects(:exists?).returns(true).at_least_once
        src.expects(:src_root).returns(Fixtures::IB_XML_SRC).at_least_once
        src.expects(:repo_shas).returns(repo_shas)
        src
      end

      cs = AssDevel::TmpInfoBase.new.connection_string
      ib = AssDevel::InfoBase
        .new('name', cs, src_mock('shas 1'), src_mock('shas 2'))
      begin
        ib.exists?.must_equal false
        ib.make
        ib.exists?.must_equal true
        ib.template_loaded?.must_equal true
      ensure
        ib.rm! :yes if ib.exists?
      end
    end
  end

  describe AssDevel::InfoBase::DbCfg do
    it '#tmp_ib' do
      infobase = mock
      infobase.expects(:platform_require).returns(PLATFORM_REQUIRE)
      inst = AssDevel::InfoBase::DbCfg.new(infobase)
      tmp_ib = inst.send(:tmp_ib)
      tmp_ib.must_be_instance_of AssDevel::TmpInfoBase
      inst.send(:tmp_ib).must_equal tmp_ib
      tmp_ib.platform_require.must_equal PLATFORM_REQUIRE
      tmp_ib.exists?.must_equal false
    end

    it '#tmp_cf' do
      inst = AssDevel::InfoBase::DbCfg.new(nil)
      tmp_cf = inst.send(:tmp_cf)
      inst.send(:tmp_cf).must_equal tmp_cf
      tmp_cf.must_match %r{\A#{Dir.tmpdir}/}
    end

    it '#dump_xml mocked' do
      seq = sequence('dump_xml')
      cfg = mock
      tmp_ib = mock
      tmp_ib.expects(:cfg).returns(cfg).at_least_once
      inst = AssDevel::InfoBase::DbCfg.new(nil)
      inst.expects(:tmp_ib).returns(tmp_ib).at_least_once
      tmp_ib.expects(:make).in_sequence(seq)
      inst.expects(:dump).with(inst.send(:tmp_cf)).in_sequence(seq).returns(:cf_path)
      cfg.expects(:load).with(:cf_path).in_sequence(seq)
      cfg.expects(:dump_xml).with(:xml_path).in_sequence(seq)
      FileUtils.expects(:rm_rf).with(inst.send(:tmp_cf)).in_sequence(seq)
      tmp_ib.expects(:rm!).in_sequence(seq)
      inst.dump_xml(:xml_path).must_equal :xml_path
    end

    include AssDevel::Support::TmpPath
    it '#dump_xml smoky' do
      begin
        xml_path = tmp_path('xml_path')
        fail if File.exists? xml_path
        ib = AssDevel::TmpInfoBase.new
        ib.make
        inst = AssDevel::InfoBase::DbCfg.new(ib)
        inst.send(:tmp_ib).exists?.must_equal false
        File.exists?(inst.send(:tmp_cf)).must_equal false
        inst.dump_xml(xml_path).must_equal xml_path
        inst.send(:tmp_ib).exists?.must_equal false
        File.exists?(inst.send(:tmp_cf)).must_equal false
        File.exists?(xml_path).must_equal true
      ensure
        FileUtils.rm_rf xml_path if File.exists? xml_path
        ib.rm!
      end
    end
  end
end
