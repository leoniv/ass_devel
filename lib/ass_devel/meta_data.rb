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

      # Mixin properties: +Name+, +Synonym+, +Comment+
      module NamedObject
        def self.class_properties
          @class_properties ||= {}
        end

        PROPS = {Имя: :Name,
                 Комментарий: :Comment,
                 Синоним: :Synonym}
        extend PropsToAccessor
      end

      # Mixin define which 1C application parts have a root common module
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
  end
end
