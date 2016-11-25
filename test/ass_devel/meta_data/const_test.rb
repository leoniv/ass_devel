require 'test_helper'

module AssDevelTest
  module Const

    describe AssDevel::MetaData::Const::RuEnNamed do
      inst = desc.new(:En, :Ru, :Module)
      klass = desc

      it "Instace method #const_name" do
        inst.const_name.must_equal "Module::En"
      end

      it "Class method .dict" do
        klass.dict.must_equal({:En => :Ru, :Ru => :En})
      end
    end

    module HaveContentTest
      extend Minitest::Spec::DSL

      it "Extended #{AssDevel::MetaData::Const::HaveContent}" do
        self.class.desc.singleton_class
          .include?(AssDevel::MetaData::Const::HaveContent).must_equal true
      end

      it "Content isn't empty" do
        self.class.desc.content.size.must_be :>, 0
      end
    end

    module ConstSetTest
      def self.included(base)
        base.desc.content.each do |elem|
          base.class_eval do
            it "#{elem.const_name}" do
              eval(elem.const_name).must_equal elem
            end

            it "Method #{base}.get" do
              self.class.desc.get(elem.ru).must_equal elem
            end
          end
        end
      end
    end

    describe AssDevel::MetaData::Const::MdCollections do
      include HaveContentTest
      include ConstSetTest

      desc.content.each do |coll|
        it "#{coll.en} #md_class.is_a? MdClass" do
          coll.md_class
            .must_be_instance_of AssDevel::MetaData::Const::MdClasses::MdClass
        end
      end
    end

    describe AssDevel::MetaData::Const::Rights do
      include HaveContentTest
      include ConstSetTest
    end

    describe AssDevel::MetaData::Const::Modules do
      include HaveContentTest
      include ConstSetTest

      it " #file_name method" do
        self.class.desc.content[0].file_name.must_equal\
          "#{self.class.desc.content[0].en}.bsl"
      end
    end

    describe AssDevel::MetaData::Const::PropTypes do
      include HaveContentTest
      include ConstSetTest

      desc.content.each do |type|
        it "#{type.en} instance of correct class" do
          type.must_be_instance_of\
            eval "AssDevel::MetaData::Const::PropTypes::Classes::#{type.en}"
        end
      end

      describe AssDevel::MetaData::Const::PropTypes::String do
        it "#valid?" do
          self.class.desc.valid?('Good value').must_equal true
          self.class.desc.valid?(:BadValue).must_equal false
        end

      end

      describe AssDevel::MetaData::Const::PropTypes::Boolean do
        it '#valid?' do
          self.class.desc.valid?(true).must_equal true
          self.class.desc.valid?(false).must_equal true
          self.class.desc.valid?(:BadValue).must_equal false
        end
      end

      describe AssDevel::MetaData::Const::PropTypes::Number do
        it '#valid?' do
          self.class.desc.valid?(0).must_equal true
          self.class.desc.valid?(0.1).must_equal true
          self.class.desc.valid?(:BadValue).must_equal false
        end
      end

      describe AssDevel::MetaData::Const::PropTypes::ReturnValuesReuse do
        def valid_values
          %w{DontUse НеИспользовать
          DuringRequest НаВремяВызова
          DuringSession НаВремяСеанса}
        end

        it '#valid?' do
          valid_values.each do |valid|
            self.class.desc.valid?(valid).must_equal true
          end
          self.class.desc.valid?(:BadValue).must_equal false
        end
      end
    end

    describe AssDevel::MetaData::Const::MdClasses do
      include HaveContentTest
      include ConstSetTest

    end

    describe AssDevel::MetaData::Const::MdProperties do
      it 'FIXME' do
        fail 'FIXME'
      end
    end
  end
end
