module AssDevel
  module MetaData
    require 'unicode'

    # Common mixins for define md objects class
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

      module HaveClassProperties
        def class_properties
          @class_properties ||= {}
        end
      end

      # Mixin provides properties: +Name+, +Synonym+, +Comment+
      module NamedObject
        extend HaveClassProperties
        PROPS = {Имя: :Name,
                 Комментарий: :Comment,
                 Синоним: :Synonym}
        extend PropsToAccessor
      end

      # Mixin provides properties for CommonModule
      module CommonModule
        extend HaveClassProperties
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

    # Describe which md objects includes or not other md objects
    module MdContainer
      # Container for md objects
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

    module Abstract
      module DSL
        def good_owners(*klasses)
          good_owners_set *klasses
        end

        def good_children(*klasses)
          good_children_set *klasses
        end
      end

      class MdObject
        extend DSL
        include I18N
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

        def self.good_owners_get
          @good_owners ||= []
        end

        def self.good_children_get
          @good_children ||= []
        end

        def self.good_owners_set(*arr)
          @good_owners = (good_owners_get += arr).uniq
        end
        private_class_method :good_owners_set

        def self.good_children_set(*arr)
          @good_children = (good_children_get += arr).uniq
        end
        private_class_method :good_children_set

        def good_owners
          self.class.good_owners_get
        end

        def good_children
          self.class.good_children_get
        end
      end

      # Top level Md objects. Object name must beginning from prefix for
      # emulate of namespace
      # Prefix separates from name underscore charclass TopMdObject
      class TopMdObject < MdObject
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
          [AppParts::Block::Subsystems::Functional]
        end
      end

      # Objects nested into other Md objects
      # laike a Attribute
      class NestedMdObject < MdObject
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

      class Subsystem < MdObject
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
            obj.is_a? Role
          end
        end
      end

      class Role < MdObject
        include MdContainer::TerminatedMdObject
      end
    end

    require 'ass_devel/meta_data/md_objects'
    require 'ass_devel/meta_data/app_parts'
  end
end
