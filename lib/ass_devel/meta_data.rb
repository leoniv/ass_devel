  module MetaData
    require 'unicode'
    module Mixins
      module PropsToAccessor
        def self.extended(base)
          base::PROPS.each do |prop, aliasing|
            base.send(:attr_accessor, prop)
            base.send(:alias_method, aliasing, prop)
            base.send(:alias_method, "#{aliasing}=".to_sym, "#{prop}=".to_sym)
          end
          base.class_properties.merge! base::PROPS
        end

        def included(base)
          base.class_properties.merge! self.class_properties
        end

        def self.included(base)
          AssDevel::MetaData::Mixins::PropsToAccessor.extended(base)
        end
      end

      module NamedObject
        def self.class_properties
          @class_properties ||= {}
        end

        PROPS = {Имя: :Name,
                 Комментарий: :Comment,
                 Синоним: :Synonym}
        extend PropsToAccessor
      end

      module HaveRootModule
        def root_module?
          true
        end

        def root_module
          @root_module ||= MdObjects::RootModule.new(self)
        end
      end

      module CommonModule
        PROPS = {
          ВнешнееСоединение: :ExternalConnection,
          ВызовСервера: :ServerCall,
          Глобальный: :Global,
          КлиентОбычноеПриложение: :ClientOrdinaryApplication,
          КлиентУправляемоеПриложение: :ClientManagedApllication,
          Привилегированный: :Privileged,
          Сервер: :Server
        }
        extend PropsToAccessor
      end
    end

    module MdContainer
      class MdObjects
        class NameCollision < StandardError; end
        # @api private
        def initialize(owner)
          @owner = owner
        end

        attr_reader :owner

        def add(object)
          fail ArgumentError unless object.is_a? MdObjects::TopMdObject
          fail NameCollision,
            "Object #{object.class}##{object.Name} already define" if define?(object)
          objects << object
        end
        alias_method :<<, :add

        def define?(object)
          get(object.class, object.Name)
        end

        def get(klass, name = '')
          objects.select do |obj|
            obj.instance_of?(klass) &&\
              (name.to_s.empty? || obj.Name =~ %r{\A#{name}\z}i)
          end
        end

        def objects
          @objects ||= []
        end
      end

      # Object which has no children like a CommonModule
      module TerminatedMdObject
        def add_md_object(object)
          fail "Object #{self.class} has no children"
        end

        def good_owners
          []
        end

        def good_children
          []
        end
      end
    end

    module MdObjects
      # @abstract
      class AbstractMdObject
        def self.class_properties
          @class_properties ||= {}
        end
        include Mixins::NamedObject
        INVALID_NAME = %r{^\d|[^a-zA-Zа-яА-Я0-9_]}
        INVALID_PREFIX = %r{^\d|[^a-zA-Zа-яА-Я0-9]}

        def self.MD_OBJECT?
          true
        end

        attr_accessor :prefix
        attr_accessor :owner

        # @param name [String Symbol] must be perfect 1C idetifier
        # @param prefix [String Symbol] mast consist letters and digits only
        #  and begining from letter
        def initialize(name, prefix = '', owner = nil, **props)
          self.prefix =  validate_prefix(prefix)
          self.attach(owner) if owner
          fill_prop(properties)
          self.Name = validate_name(name)
          yield self if block_given?
        end

        def validate_prefix(prefix)
          return prefix.to_s if prefix.to_s.empty?
          fail ArgumentError, "Invalid prefix `#{prefix}'" if\
            prefix.to_s =~ INVALID_PREFIX
          prefix.to_s
        end
        private :validate_prefix

        def fill_prop(**props)
          props.each do |p,v|
            self.send(p, v)
          end
        end
        private :fill_prop

        def validate_name(name)
          fail ArgumentError, "Invalid name `#{name}'" if\
            name.to_s =~ INVALID_NAME
          fail ArgumentError, "Name must have prefix `#{prefix}_'" unless\
            prefixed?(name)
          name.to_s
        end
        private :validate_name

        def prefixed?(name)
          return true if prefix.empty?
          name.to_s =~ %r{#{prefix}_}
        end
        private :prefixed?

        def self.properties
          return superclass.properties.merge class_properties if\
            superclass.respond_to? :MD_OBJECT?
          class_properties
        end

        def properties
          self.class.properties
        end

        def attached?
          !onwer.nil?
        end

        def attach(owner)
          fail ArgumentError if attached?
          fail_if_bad_owner(owner)
          owner.add_md_object(self)
          self.owner = owner
        end

        def root
          return nil unless attached?
          root_get
        end

        def root_get
          fail 'Abstract method call'
        end
        private :root_get

        def configuration
          return nil unless attached?
          configuration_get
        end

        def configuration_get
          fail 'Abstract method call'
        end
        private :configuration_get

        def add_md_object(object)
          fail 'Abstract method call'
        end

        def fail_if_bad_owner(owner)
          fail ArgumentError unless owner.may_i_attach?(self)
        end
        private :fail_if_bad_owner

        def may_i_attach?(child)
          good_child?(child) && child.good_owner?(self)
        end

        def good_owner?(owner)
          good_owners.include? owner.class
        end

        def good_child?(child)
          good_children.include? child
        end

        def good_owners
          fail 'Abstract method call'
        end

        def good_children
          fail 'Abstract method call'
        end
      end

      # @abstract
      # Top level Md objects. Object name must beginning from prefix for
      # emulate of namespace
      # Prefix separates from name underscore charclass TopMdObject
      class TopMdObject < AbstractMdObject
        # @param name [String Symbol] must be perfect 1C idetifier
        # @param prefix [String Symbol] mast consist letters and digits only
        #  and begining from letter
        def initialize(name, subsytem, **props)
          super name, subsytem.prefix, subsytem, **props
        end

        def root_get
          owner.root
        end

        def configuration_get
          root.configuration
        end

        def good_owners
          [Subsystem::Functional]
        end
      end

      # @abstract
      # Objects nested into other Md objects
      # laike a Attribute
      class NestedMdObject < AbstractMdObject
        def initialize(name, owner, **props)
          super name, '', owner, **props
        end

        def configuration_get
          root.configuration
        end

        def root_get
          return owner if owner.instance_of? TopMdObject
          owner.root
        end

        def good_owners
          [TopMdObject, NestedMdObject]
        end
      end

      module Roles
        # @abstract
        class AbstractRole < AbstractMdObject
          include MdContainer::TerminatedMdObject
        end

        # @abstract
        class FunctionalRole < AbstractRole
          'TODO:'
        end

        # @abstract
        class ApplicationRole < AbstractRole
          'TODO:'
        end

        class UiRole < AbstractRole
          'TODO: просмотр для подситемы'
        end

        class ReadOnly < AbstractRole
          def initialize(block)
            fail 'FIXME'
          end
          'TODO:'
        end

        class Read < FunctionalRole
          'TODO:'
        end

        class ReadWriteUpdate < FunctionalRole
          'TODO:'
        end

        class Admin < ApplicationRole
          'TODO:'
        end

        class BaseUser < ApplicationRole
          'TODO:'
        end

        class AdvancedUser < ApplicationRole
          'TODO:'
        end

        class RunExternals < ApplicationRole
          'TODO: интерактивное открытие вненшних обработок отчетов'
        end

        class SuperUser < ApplicationRole
          'TODO: ПолныеПрава'
        end
      end

      module Subsystems
        class BadPrefix < StandardError; end
        # @abstract
        class AbstractSubsystem < AbstractMdObject
          PROPS = {
            ВключатьВКомандныйИнтерфейс: :IncludeInCommandInterface,
            ВключатьСправкуВСодержание: :IncludeHelpInContents,
            КомандныйИнтерфейс: :CommandInterface,
            Пояснение: :Explanation
          }
          include Mixins::PropsToAccessor

          def Content
            @Content ||= MdContainer::MdObjects.new(self)
          end

          def Subsystems
            @Subsystems ||= MdContainer::MdObjects.new(self)
          end

          def add_md_object(object)
            if object.is_a? AbstractSubsystem
              Subsystems().add(object)
            else
              Content().add(object)
            end
          end

          def roles
            Content().objects.select do
              obj.is_a? Roles::AbstractRole
            end
          end
        end

        class Application < AbstractSubsystem
          'TODO:'
          def good_owners
            [::Application::Configuration]
          end

          def good_children
            [Roles::Admin,
             Roles::BaseUser,
             Roles::AdvancedUser,
             Roles::RunExternals,
             Roles::SuperUser,
             Special::RootModule
            ]
          end

          def IncludeInCommandInterface
            false
          end
        end

        class Block < AbstractSubsystem
          include Mixins::HaveRootModule

          attr_accessor :app_src
          def initialize(prefix, app_src, **props)
            super "#{prefix}_Block", prefix, nil, **props
            add_md_object(root_module)
            add_md_object(read_only_role)
            self.app_src = app_src
          end

          def good_owners
            [Application::Configuration]
          end

          def read_only_role
            @read_only_role ||= Roles::ReadOnly.new(self)
          end

          def good_children
            [Special::RootModule,
             Roles::ReadOnly,
             Functional]
          end

          def IncludeInCommandInterface
            false
          end

          def app_src
            fail 'FIXME'
          end
        end

        class Functional < AbstractSubsystem
          def initialize(name, block, **props)
            super name, '', block, **props)
            fail 'FIXME'
          end

          def good_owners
            [Block]
          end

          def good_children
            [Roles::Read, Roles::ReadWriteUpdate]
          end

          def good_child?(child)
            return true if child.is_a? TopMdObject
            super
          end

          def may_i_attach?(child)
            fail BadPrefix, "#{child.prefix} != #{root.prefix}" if\
              child.prefix != root.prefix
            super
          end

          def IncludeInCommandInterface
            false
          end
        end

        class UiSection < AbstractSubsystem
          'TODO:'
          def IncludeInCommandInterface
            true
          end

          def good_owners
            [Application::Configuration]
          end

          def good_child?(child)
            fail 'FIXME'
          end
        end

        class UiSubssection < AbstractSubsystem
          'TODO:'

          def good_owners
            [UiSection]
          end

          def good_child?(child)
            fail 'FIXME'
          end

          def IncludeInCommandInterface
            true
          end
        end
      end

      module Special
        class RootModule < AbstractMdObject
          include Mixins::CommonModule
          include MdContainer::TerminatedMdObject
          DEFAULT_PROPS = {FIXME: 'FIXME'}
          def initialize(subsytem)
            super "#{subsytem.prefix}_Root",subsytem.prefix,
              subsytem, **DEFAULT_PROPS
          end

          def good_owners
            [Subsystem::Block]
          end

          def root_get
            owner
          end

          def configuration_get
            owner.configuration
          end
        end
      end

      # Must consist only 1C Application md objects wrappers
      # All classes must be subclass of TopMdObject
      module Application
        class CommonModule < TopMdObject
          include Mixins::CommonModule
          include MdContainer::TerminatedMdObject
          'TODO:'
        end

        class Configuration < AbstractMdObject
          class PrefixCollision < StandardError; end
          PROPS = {АвторскиеПрава: :Copyright,
                   АдресИнформацииОКонфигурации: :ConfigurationInformationAddress,
                   АдресИнформацииОПоставщике: :VendorInformationAddress,
                   АдресКаталогаОбновлений: :UpdateCatalogAddress,
                   Версия: :Version,
                   КраткаяИнформация: :BriefInformation,
                   ПодробнаяИнформация: :DetailedInformation}

          include Mixins::PropsToAccessor
          include Mixins::HaveRootModule
          def blocks
            prefixes.values
          end

          # TODO: языки?

          def app_src
            fail 'FIXME'
          end

          def prefixes
            @prefixes ||= {}
          end

          def prefixes_add(prefix, owner)
            return prefix if prefix.to_s.empty?
            fail PrefixCollision, "Prefix `#{prefix}' already define"\
              " in #{prefixes_get(prefix)}" if prefixes_get(prefix)
            prefixes[norm_prefix(prefix)] = owner
          end
          private :prefixes_add

          def prefixes_get(prefix)
            prefixes[norm_prefix(prefix)]
          end
          private :prefixes_get

          def norm_prefix(prefix)
            Unicode.downcase(prefix.to_s)
          end
          private :norm_prefix

          def <<(block)
#            FIXME
#            fail ArgumentError unless block.is? Subsystem
#            prefixes_add subsytem.prefix, subsytem
          end

          def block(block)
            fail ArgumentError unless block.is? Subsystems::Block
            prefixes_add block.prefix, block

          end
        end

        class DataProcessor < TopMdObject
          'TODO:'
        end

        class Report < TopMdObject
          'TODO:'
        end
      end

      # Consists only tow class DataProcessor and Report
      module Externals
        class DataProcessor < NestedMdObject
          'TODO:'
        end

        class Report < NestedMdObject
          'TODO:'
        end
      end
    end
  end
