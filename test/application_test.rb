require 'test_helper'
module AssDevelTest
  describe AssDevel::Application::Src do
    def inst_stub
      @inst_stub ||= Class.new AssDevel::Application::Src do
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
