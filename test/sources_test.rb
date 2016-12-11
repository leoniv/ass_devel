require 'test_helper'

module AssDevelTest
  describe AssDevel::Sources::HaveRootFile do
    include desc
    def self.ROOT_FILE
      name
    end

    it '#root_file' do
      self.expects(:src_root).returns('src_root')
      root_file.must_equal "src_root/#{self.class.name}"
    end
  end

  describe AssDevel::Sources::DumperVersionWriter do
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
        AssDevel::Sources::Abstract::Src.new('')
      }.must_raise ArgumentError
      e.message.must_match %r{src_root must not be nil}
    end

    it '#initialize fail' do
      old_platform_require = AssDevel::InfoBase.config.platform_require
      begin
        AssDevel::Sources::Abstract::Src.any_instance
          .expects(:fail_if_repo_not_clear)
        inst = AssDevel::Sources::Abstract::Src.new(:src_root)
        inst.src_root.must_equal :src_root
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

    it '#dumper_version' do
      assert_it_abstract inst_stub, :dumper_version
    end

    it '#dump' do
      assert_it_abstract inst_stub, :dump
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
      assert_it_abstract inst_stub, :init_src
    end
  end
end
