require 'test_helper'

module AssDevelTest
  describe AssDevel::Cycles::Mixins::Release do
    def desc
      self.class.desc
    end

    it 'TAG_PREFIX' do
      desc::TAG_PREFIX.must_equal 'v'
    end

    it 'VERSION_PATTERN' do
      desc::VERSION_PATTERN
        .must_equal '\d+\.\d+\.\d+((\.\d+)|(\.[a-z]+))*'
    end

    it 'VERSION_REGEX' do
      desc::VERSION_REGEX.must_equal %r{^#{desc::VERSION_PATTERN}\z}
    end

    it 'VERSION_TAGS_REGEX' do
      desc::VERSION_TAGS_REGEX.must_equal %r{^v#{desc::VERSION_PATTERN}\z}
    end

    def valid_versions
      [
      '10.20.30',
      '10.20.30.40',
      '10.20.30.pre.10',
      '10.20.30.40.pre.10'
      ]
    end

    it '.version_tag' do
      valid_versions.each do |v|
        desc.version_tag(v).must_equal "v#{v}"
      end
    end

    it '.version_tag fail' do
      e = proc {
        desc.version_tag '1.2.bad.1'
      }.must_raise ArgumentError
      e.message.must_match %r{Invalid version string}i
    end

    it '.versions' do
      desc.expects(:version_tags).returns(valid_versions.map {|v| "v#{v}"})
      desc.versions.must_equal\
        valid_versions.map {|v| Gem::Version.new(v)}.sort
    end

    it '.version_tags' do
      desc.expects(:handle_shell).with('git tag').returns(
        (valid_versions.map {|v| "v#{v}"} + ['Invalid version']).join("\n")
      )
      desc.version_tags.must_equal valid_versions.map {|v| "v#{v}"}
    end

    def inst
      @inst ||= class_.new
    end

    def class_
      @class_ ||= Class.new do
        include AssDevel::Cycles::Mixins::Release
      end
    end

    it '#version_tag' do
      inst.expects(:app_version).returns(:version)
      desc.expects(:version_tag).with(:version).returns(:version_tag)
      inst.version_tag.must_equal :version_tag
    end

    it '#tag_version' do
      inst.expects(:app_version).returns(:app_version)
      inst.expects(:version_tag).returns(:version_tag)
      inst.expects(:handle_shell)
        .with("git tag -m \"Version app_version\" version_tag")
        .returns(:git_tag)
      inst.tag_version.must_equal :git_tag
    end

    it 'class_.versions' do
      desc.expects(:versions).returns(:versions)
      class_.versions.must_equal :versions
    end

    it 'class_.version_tags' do
      desc.expects(:version_tags).returns(:version_tags)
      class_.version_tags.must_equal :version_tags
    end

    it '#tag_exist? true' do
      class_.expects(:version_tags).returns(['v1','v2','v3'])
      inst.expects(:version_tag).returns('v1')
      inst.tag_exist?.must_equal true
    end

    it '#tag_exist? true' do
      class_.expects(:version_tags).returns(['v1','v2','v3'])
      inst.expects(:version_tag).returns('v0')
      inst.tag_exist?.must_equal false
    end
  end
end
