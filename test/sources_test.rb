require 'test_helper'

module AssDevelTest
  module AssertItAbstract
    def assert_it_abstract(method, *args)
      e = proc {
        inst_stub.send(method, *args)
      }.must_raise RuntimeError
      e.message.must_match %r{abstract method}i
    end
  end

  describe AssDevel::Sources::Abstract::HaveRootFile do
    include desc
    def self.ROOT_FILE
      name
    end

    it '#root_file' do
      self.expects(:src_root).returns('src_root')
      root_file.must_equal "src_root/#{self.class.name}"
    end
  end

  describe AssDevel::Sources::Abstract::DumperVersionWriter do
    include desc
    it '#read_dumper_version' do
      self.expects(:dumper_version_file).returns(:dumper_version_file)
      File.expects(:read).with(:dumper_version_file).returns('42')
      read_dumper_version.must_equal '42'
    end

    it '#dumper_version_file' do
      self.expects(:src_root).returns('src_root')
      dumper_version_file.must_equal "src_root/.dumper_version"
    end

    it '#write_dumper_version' do
      seq = sequence('write')
      io = mock
      io.expects(:write).with('dumper_version').in_sequence(seq)
      io.expects(:close).in_sequence(seq).returns(42)
      self.expects(:dumper_version_file).returns(:dumper_version_file).twice

      FileUtils.expects(:touch).with(:dumper_version_file)
      File.expects(:open).with(:dumper_version_file, 'w').returns(io)

      write_dumper_version(:dumper_version).must_equal 42
    end
  end

  describe AssDevel::Sources::Abstract::Src do
    include AssertItAbstract
    def inst_stub
      @inst_stub ||= Class.new AssDevel::Sources::Abstract::Src do
        def initialize(*_)

        end
      end.new
    end

    it '#initialize fail' do
      e = proc {
        AssDevel::Sources::Abstract::Src.new('', :owner)
      }.must_raise ArgumentError
      e.message.must_match %r{src_root must not be nil}
    end

    it '#initialize fail' do
      old_platform_require = AssDevel::InfoBase.config.platform_require
      begin
        AssDevel::Sources::Abstract::Src.any_instance
          .expects(:fail_if_repo_not_clear)
        AssDevel::Sources::Abstract::Src.any_instance
          .expects(:platform_require).returns(:platform_require)
        inst = AssDevel::Sources::Abstract::Src.new(:src_root, :owner)
        inst.src_root.must_equal :src_root
        inst.owner.must_equal :owner
        AssDevel::InfoBase.config.platform_require.must_equal :platform_require
      ensure
        AssDevel::InfoBase.config.platform_require = old_platform_require
      end
    end

    it 'fail_if_repo_not_clear fail' do
      inst_stub.expects(:repo_clear?).returns(false)
      e = proc {
        inst_stub.send(:fail_if_repo_not_clear)
      }.must_raise RuntimeError
      e.message.must_match %r{Repo not clear}i
    end

    it 'fail_if_repo_not_clear not fail' do
      inst_stub.expects(:repo_clear?).returns(true)
      assert_nil inst_stub.send(:fail_if_repo_not_clear)
    end

    it '#platform_require fail' do
      owner = mock
      owner.expects(:platform_require).returns(nil)
      inst_stub.expects(:owner).returns(owner)
      e = proc {
        inst_stub.platform_require
      }.must_raise RuntimeError
      e.message.must_match %r{Not specified platform_require}i
    end

    it '#platform_require not fail' do
      owner = mock
      owner.expects(:platform_require).returns(:platform_require).twice
      inst_stub.expects(:owner).returns(owner).twice
      inst_stub.platform_require.must_equal :platform_require
    end

    it '#dumper_version' do
      assert_it_abstract :dumper_version
    end

    it '#dump' do
      assert_it_abstract :dump
    end

    it '#exists?' do
      File.expects(:exists?).with(:src_root).returns(:exists?)
      inst_stub.expects(:src_root).returns(:src_root)
      inst_stub.exists?.must_equal :exists?
    end

    def revision_cmd(src_root)
      "git log --pretty=format:'%h' -n 1 #{src_root}"
    end

    it '#revision' do
      inst_stub.expects(:src_root).returns(:src_root)
      inst_stub.expects(:handle_shell)
        .with(revision_cmd(:src_root)).returns(:revision)
      inst_stub.revision.must_equal :revision
    end

    it '#revision smoky' do
      inst_stub.handle_shell(revision_cmd('.')).must_match %r{[a-f0-9]+}i
    end

    it '#repo_clear? true' do
      inst_stub.expects(:repo_status).returns('')
      inst_stub.repo_clear?.must_equal true
    end

    it '#repo_clear? false' do
      inst_stub.expects(:repo_status).returns('status')
      inst_stub.repo_clear?.must_equal false
    end

    def repo_status_cmd(src_root)
      "git status -s #{src_root}"
    end

    it '#repo_status' do
      inst_stub.expects(:src_root).returns(:src_root)
      inst_stub.expects(:handle_shell).with(repo_status_cmd(:src_root))
        .returns(:repo_status)
      inst_stub.repo_status.must_equal :repo_status
    end

    it '#repo_status smoky' do
      inst_stub.handle_shell repo_status_cmd('.').must_match %r{.}
    end

    def repo_ls_tree_cmd(src_root)
      "git ls-tree -r HEAD #{src_root}"
    end

    it '#repo_ls_tree' do
      inst_stub.expects(:src_root).returns(:src_root)
      inst_stub.expects(:handle_shell).with(repo_ls_tree_cmd(:src_root))
        .returns(:repo_ls_tree)
      inst_stub.repo_ls_tree.must_equal :repo_ls_tree
    end

    it '#repo_ls_tree smokt' do
      inst_stub.handle_shell repo_ls_tree_cmd('.').must_match %r{.}
    end

    def repo_add_to_index(src_root)
      "git add #{src_root}"
    end

    it '#repo_add_to_index' do
      inst_stub.expects(:src_root).returns(:src_root)
      inst_stub.expects(:handle_shell).with(repo_add_to_index(:src_root))
      inst_stub.repo_add_to_index
    end

    it '#rm_rf!' do
      seq = sequence('rm_rf!')
      inst_stub.expects(:fail_if_repo_not_clear)
      inst_stub.expects(:src_root).returns(:src_root.to_s)
      Dir.expects(:glob).with('src_root/*').in_sequence(seq).returns(:dir_glob)
      FileUtils.expects(:rm_rf).with(:dir_glob).in_sequence(seq).returns(:rm_rf)
      inst_stub.rm_rf!.must_equal :rm_rf
    end

    it '#handle_shell fail' do
      e = proc {
        inst_stub.handle_shell 'bad_command_name'
      }.must_raise RuntimeError
      e.message.must_match %r{(sh:)? bad_command_name}
    end

    it '#handle_shell' do
      refute_nil inst_stub.handle_shell 'true'
    end

    it '#init_src' do
      assert_it_abstract :init_src
    end
  end

  describe AssDevel::Sources::Abstract::CfgSrc do
    include AssertItAbstract

    def inst_stub(owner = nil)
      @inst_stub ||= Class.new(AssDevel::Sources::Abstract::CfgSrc) do
        def initialize(owner)
          @owner = owner
        end
      end.new(owner)
    end

    it '.ROOT_FILE' do
      AssDevel::Sources::Abstract::CfgSrc.ROOT_FILE
        .must_equal 'Configuration.xml'
    end

    it '#root_file' do
      inst_stub.expects(:src_root).returns('src_root')
      inst_stub.root_file.must_equal "src_root/#{self.class.desc.ROOT_FILE}"
    end

    it '#dumper_version' do
      owner = mock
      owner.expects(:dumper_version).returns(:dumper_version)
      inst_stub(owner).dumper_version.must_equal :dumper_version
    end

    it '#src_root' do
      owner = mock
      owner.expects(:src_root).returns('owner_src_root')
      inst_stub(owner).class.expects(:DIR).returns('dir')
      inst_stub.src_root.must_equal 'owner_src_root/dir'
    end

    it '#info_base or #ib' do
      owner = mock
      owner.expects(:info_base).returns(:info_base).twice
      inst_stub(owner).info_base.must_equal :info_base
      inst_stub.ib.must_equal :info_base
    end

    it '#dump_' do
      assert_it_abstract :dump_
    end

    it '#dump' do
      seq = sequence('dump')
      inst_stub.expects(:exists?).in_sequence(seq).returns(true)
      inst_stub.expects(:rm_rf!).in_sequence(seq)
      inst_stub.expects(:dump_).in_sequence(seq)
      inst_stub.expects(:repo_add_to_index).in_sequence(seq).returns(:add_index)
      inst_stub.dump.must_equal :add_index
    end

    it '#dump fail if not exists' do
      inst_stub.expects(:exists?).returns(false)
      e = proc {
        inst_stub.dump
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

      owner = mock

      inst_stub(owner).expects(:exists?).in_sequence(seq).returns(false)
      inst_stub.expects(:platform_require).in_sequence(seq).returns('42')
      AssDevel::TmpInfoBase.expects(:make_rm)
        .in_sequence(seq).with(platform_require: '42').yields(ib)
      inst_stub.expects(:src_root).in_sequence(seq).returns(:src_root)
      FileUtils.expects(:mkdir_p).in_sequence(seq).with(:src_root)
      owner.expects(:write_dumper_version).with(:dumper_version)
        .in_sequence(seq)
      inst_stub.expects(:src_root).in_sequence(seq).returns(:src_root)
      cfg.expects(:dump_xml).in_sequence(seq).with(:src_root)
      inst_stub.expects(:repo_add_to_index).returns(:add_index)

      inst_stub.init_src.must_equal :add_index
    end
  end

  describe AssDevel::Sources::Application::DbCfgSrc do
    def inst_stub
      @inst_stub ||= Class.new(AssDevel::Sources::Application::DbCfgSrc) do
        def initialize

        end
      end.new
    end

    it '.DIR' do
      inst_stub.class.DIR.must_equal 'db_cfg.src'
    end

    it '#dump_' do
      info_base = mock
      db_cfg = mock

      info_base.expects(:db_cfg).returns(db_cfg)
      db_cfg.expects(:dump_xml).with(:src_root).returns(:dump_)

      inst_stub.expects(:info_base).returns(info_base)
      inst_stub.expects(:src_root).returns(:src_root)
      inst_stub.send(:dump_).must_equal :dump_
    end
  end

  describe AssDevel::Sources::Application::CfgSrc do
    def inst_stub
      @inst_stub ||= Class.new(AssDevel::Sources::Application::CfgSrc) do
        def initialize

        end
      end.new
    end

    it '.DIR' do
      inst_stub.class.DIR.must_equal 'cfg.src'
    end

    it '#dump_' do
      info_base = mock
      cfg = mock

      info_base.expects(:cfg).returns(cfg)
      cfg.expects(:dump_xml).with(:src_root).returns(:dump_)

      inst_stub.expects(:info_base).returns(info_base)
      inst_stub.expects(:src_root).returns(:src_root)
      inst_stub.send(:dump_).must_equal :dump_
    end
  end

  describe AssDevel::Sources::Application do
    def inst_stub
      @inst_stub ||= Class.new AssDevel::Sources::Application do
        def initialize

        end
      end.new
    end
    it '#initialize' do
      skip
    end

    it '#init_src' do
      skip
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
end
