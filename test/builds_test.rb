require 'test_helper'

module AssDevelTest
  describe AssDevel::Builds::Abstract::Build do
    include AssertItAbstract

    def inst
      @inst ||= AssDevel::Builds::Abstract::Build.new(:key, opt1: 1)
    end

    it '#initialize' do
      inst.key.must_equal :key
      inst.options.must_equal opt1: 1
    end

    it '#build' do
      inst.expects(:build_).returns(:build_)
      inst.build(:src, :spec).must_equal :build_
      inst.src.must_equal :src
      inst.spec.must_equal :spec
    end

    it '#build_' do
      assert_it_abstract inst, :build_
    end

    it '#name' do
      assert_it_abstract inst, :name
    end

    it '#version' do
      spec = mock
      spec.responds_like AssDevel::Application::Specification.new
      inst.expects(:spec).returns(spec)
      spec.expects(:version).returns(:version)
      inst.version.must_equal(:version)
    end

    it '#revision' do
      src = mock
      src.responds_like AssDevel::Sources::Abstract::Src.new('src_root')
      inst.expects(:src).returns(src)
      src.expects(:revision).returns(:revision)
      inst.revision.must_equal(:revision)
    end

    it '#built?' do
      assert_it_abstract inst, :built?
    end
  end

  describe AssDevel::Builds::Abstract::FileBuild do
    include AssertItAbstract
    def inst
      @inst ||= AssDevel::Builds::Abstract::FileBuild.new(:key, :dir, opt1: 1)
    end

    it '#initialize' do
      inst.dir.must_equal :dir
      inst.key.must_equal :key
      inst.options.must_equal opt1: 1
    end

    it '#build_' do
      inst.expects(:dir).returns(:dir)
      FileUtils.expects(:mkdir_p).with(:dir)
      inst.build_
    end

    it '#name with key' do
      spec = mock
      spec.expects(:name).returns(:spec_name)
      inst.expects(:spec).returns(spec)
      inst.expects(:version).returns(:version)
      inst.expects(:revision).returns(:revision)
      inst.expects(:key).returns(:key).twice
      inst.expects(:ext).returns(:ext)
      inst.name.must_equal 'spec_name.key.version.revision.ext'
    end

    it '#name without key' do
      spec = mock
      spec.expects(:name).returns(:spec_name)
      inst.expects(:spec).returns(spec)
      inst.expects(:version).returns(:version)
      inst.expects(:revision).returns(:revision)
      inst.expects(:key).returns(nil)
      inst.expects(:ext).returns(:ext)
      inst.name.must_equal 'spec_name.version.revision.ext'
    end

    it '#ext' do
      assert_it_abstract inst, :ext
    end

    it '#build_path' do
      inst.expects(:name => :name, :dir => :dir)
      File.expects(:join).with(:dir, :name).returns(:build_path)
      inst.build_path.must_equal :build_path
    end
  end
end
