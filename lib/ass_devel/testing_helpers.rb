module AssDevel
  module TestingHelpers
    # Helper for tesing private methods 1C object
    # Tested 1C module must have TestGateWay method
    # module of 1C Form must have TestEvalOnServer methods.
    #
    # @example
    #
    #  # For modules of objects exclude Form modules:
    #
    #  #// Hole for testing
    #  #function TestGateWay(EvalStr,Arguments) export
    #  #   return eval(EvalStr);
    #  #endfunction
    #
    #  # For Form modules:
    #
    #  #// Hole for testing
    #  #&AtClient
    #  #function TestGateWay(EvalStr,Arguments) export
    #  #   return eval(EvalStr);
    #  #endfunction
    #
    #  #&AtServer
    #  #function TestEvalOnServer(EvalStr,Arguments)
    #  #    return eval(EvalStr);
    #  #endfunction
    #
    # For easy to use this uses {Wrappers}
    #
    # @example
    #   describe 'example' do
    #     like_ole_runtime Runtimes::Thin
    #     include AssDevel::TestingHelpers::TestGateWay::Wrappers::DSL
    #
    #     def form
    #       @form ||= wrapp_form('Catalog.CatalogName.ListForm')
    #     end
    #
    #     it 'call private #method_foo' do
    #       form.client.method_foo.must_equal 'foo'
    #     end
    #
    #     it 'get property QueryText of DynamicList attribute from serever' do
    #       form.server.prop.DynamicList.QueryText.must_equal 'select 42'
    #     end
    #   end
    #
    # @api private
    module TestGateWay
      require 'ass_ole/snippets/shared'
      include AssOle::Snippets::Shared::Structure
      # Returns eval_str and arguments structure for
      # clall method of 1C Object #TestGateWay
      # It make possable testing private object methods
      # @param method [Symbol String] tested method name
      # @param args [Hash] tested method arguments
      # @return [Array] [0] is eval_str [1] is structure
      # @example
      #   args = {foo: 'value'}
      #   eval_str, args = gate_way_eval_str(:method_bar, args)
      #   AssObject.testGateWay(eval_str, args)
      #
      def gate_way_eval_str(method, **args)
        ["#{method}(#{args.keys.map{|k| "Arguments.#{k}"}.join(',')})",
          structure(**args)]
      end

      def _test_gate_way(obj, method, **args)
        eval_str, args = gate_way_eval_str method, **args
        obj.TestGateWay(eval_str, args)
      end

      def _test_eval_on_server(obj, method, **args)
        eval_str, args = gate_way_eval_str(method, **args)
        _test_gate_way(obj, :TestEvalOnServer, EvalStr: eval_str, Arguments: args)
      end

      def _test_property_get(obj, prop)
        eval_str, args = gate_way_eval_str(prop)
        eval_str.gsub!('()','')
        _test_gate_way(obj, :TestEvalOnServer, EvalStr: eval_str, Arguments: args)
      end

      # @todo make wrappers for ObjectModule, ManagerModule etc
      module Wrappers
        # @todo (see Wrappers)
        module DSL
          def wrapp_form(name)
            ole = getForm(name)
            Wrappers::Form.new(ole, ole_runtime_get)
          end
        end

        class Form
          class Context
            attr_reader :form, :context
            def initialize(form)
              @form = form
            end

            def method_missing(method, **args)
              return form.gate_way._test_gate_way(form.ole, method, **args) if\
                self.is_a? Context::Client
              form.gate_way._test_eval_on_server(form.ole, method, **args)
            end

            class Server < Context
              class ProperyGetter
                attr_reader :context
                def initialize(context)
                  @context = context
                end

                def stack
                  @stack ||= []
                end
                private :stack

                def name
                  r = stack.map(&:to_s).join('.')
                  satck.clear
                  r
                end
                private :name

                def get
                  context.form.gate_way._test_property_get context.form.ole, name
                end

                def method_missing(method, *_)
                  return get.send(method, *_) if method.to_s =~ %r{^must_}
                  stack << method
                  self
                end
              end

              def prop
                ProperyGetter.new(self)
              end
            end

            class Client < Context; end
          end

          attr_reader :ole, :gate_way
          def initialize(ole_form, ole_runtime)
            @ole = ole_form
            @gate_way = Class.new do
              like_ole_runtime ole_runtime
              include TestGateWay
            end.new
          end

          def method_missing(method, *args)
            ole.send(method, *args)
          end

          def server
            Context::Server.new(self)
          end

          def client
            Context::Client.new(self)
          end
        end
      end
    end

    # Provides dynamically generated mixins-helpers
    # @example
    #
    # describe 'Tests for Catalogs.CatalogName' do
    #   like_ole_runtime Runtimes::Ext
    #   include AssDevel::TestingHelpers::MetaData::Catalogs[:CatalogName]
    #
    #   def catalog_item
    #     new_item Description: 'Foo' do |obj|
    #       obj.attr1 = 'bar'
    #     end
    #   end
    #
    #   it 'Item method #foo' do
    #      catalog_item.foo.must_equal 'foo'
    #   end
    #
    #   it 'ManagerModule method #bar' do
    #     catalog_manager.bar.must_equal 'bar'
    #   end
    # end
    module MetaData
      module Managers
        # @todo add DocumentManger, TaskManger etc.
        module Abstract
          module AbstractObjectManager
            # Symbol like a :Catalogs, :Constants
            def md_collection
              fail 'Abstract method call'
            end

            def objects_manager
              fail "Manager #{md_collection}.#{self.MD_NAME} not found" unless\
                send(md_collection).ole_respond_to? self.MD_NAME
              send(md_collection).send(self.MD_NAME)
            end

            def object_metadata
              mEtadata.send(md_collection).send(self.MD_NAME)
            end

            # Abstract method must be redefined in module
            # For example catatlogs makes with method :CreateItem
            # but for Documents uses method :CreateDocument
            def _new_object_method
              fail 'Abstract method call'
            end
            private :_new_object_method

            def _new_object
              objects_manager.send(_new_object_method)
            end
            private :_new_object

            # Make new object. Only make and not write
            # @return [WIN32OLE] object not ref!
            def new_object(**attributes, &block)
              obj = _fill_attr(_new_object, **attributes)
              yield obj if block_given?
              obj
            end

            def _fill_attr(obj, **attributes)
              attributes.each do |k, v|
                obj.send("#{k}=", v)
              end
              obj
            end
            private :_fill_attr

            # Make new object and write them
            # @return [WIN32OLE] object not ref!
            def make_object(**attributes, &block)
              obj = new_object(**attributes, &block)
              _write(obj)
              obj
            end

            # If for write real object uses not :Write method it must be
            # redefined in module
            def _write(obj)
              obj.Write()
            end
            private :_write
          end

          module AbstractGroupedObject

            # Make new object grouo. Only make and not write
            # @return [WIN32OLE] object not ref!
            def new_group(**attributes, &block)
              obj = _fill_attr(_new_group, **attributes)
              yield obj if block_given?
              obj
            end

            def _new_group
              objects_manager.send(:CreateFolder)
            end
            private :_new_group

            # Make new object group and write them
            # @return [WIN32OLE] object not ref!
            def make_group(**attributes, &block)
              obj = new_group(**attributes, &block)
              _write(obj)
              obj
            end
          end

          module AbstractRegisterManager
            include AssOle::Snippets::Shared::Structure
            include AssOle::Snippets::Shared::Array
            require 'date'

            def register_manager
              fail "Manager #{md_collection}.#{self.MD_NAME} not found" unless\
                send(md_collection).ole_respond_to? self.MD_NAME
              send(md_collection).send(self.MD_NAME)
            end

            def register_record_key
              ([:Period, :Recorder, :LineNumber] + register_dimensions).select do |k|
                record_key.ole_respond_to? k
              end
            end

            def register_metadata
              mEtadata.send(md_collection).send(self.MD_NAME)
            end

            def register_dimensions
              r = []
              register_metadata.Dimensions.each do |d|
                r << d.Name.to_sym
              end
              r
            end

            def record_set(**options, &block)
              rs = register_manager.CreateRecordSet
              options.each do |k, v|
                rs.Filter.send(k).Set(v, true)
              end
              yield rs if block_given?
              rs
            end

            def record_key(options = {})
              register_manager.CreateRecordKey(structure(**options))
            end
          end

          module CatalogManager
            include AbstractObjectManager
            include AbstractGroupedObject

            def md_collection
              :Catalogs
            end

            def _new_object_method
              :CreateItem
            end

            alias_method :catalog_manager, :objects_manager
            alias_method :catalog_metadata, :object_metadata
            alias_method :new_item, :new_object
            alias_method :make_item, :make_object
            alias_method :new_folder, :new_group
            alias_method :make_folder, :make_group
          end

          module ConstantManager
            def md_collection
              :Constants
            end

            def constant_manager
              cOnstants.send(self.MD_NAME)
            end

            def constant_value_manager
              constant_manager.CreateValueManager
            end
          end

          module InformationRegisterManager
            include AbstractRegisterManager

            def md_collection
              :InformationRegisters
            end

            def record_manager(**options, &block)
              rm = register_manager.CreateRecordManager
              options.each do |k, v|
                rm.send("#{k}=", v)
              end
              yield rm if block_given?
              rm
            end
          end
        end

        ABSTRACTS_ABSTRACTS = [:AbstractObjectManager,
                               :AbstractRegisterManager,
                               :AbstractGroupedObject]

        ABSTRACTS = (Abstract.constants - ABSTRACTS_ABSTRACTS).map do |c|
          Abstract.const_get(c)
        end

        # @api private
        module ManagersHolder
          def manager_holder?
            true
          end

          def content
            @content ||= {}
          end

          def [](md_name)
            r = content_get(md_name.to_s)
            fail ArgumentError,
              "#{md_collection_name}[:#{md_name}] not found" unless r
            r
          end

          def content_get(md_name)
            return content[md_name] if content[md_name]

            md_object = md_object_get(md_name)
            content[md_object.Name] = build_manager(md_object, abstract_module)
            content[md_name]
          end

          def md_object_get(md_name)
            Class.new do
              def initialize(md_name)
                @md_name = md_name
              end

              def Name
                @md_name
              end
            end.new(md_name)
          end

          def build_manager(md_object, abstract_module)
            r = Module.new do
              include abstract_module

              define_method :MD_NAME do
                md_object.Name
              end
            end
          end

          def method_missing(method, *args)
            content_get(method)
          end

          attr_reader :abstract_module
          attr_reader :md_collection_name
        end

        def self.build_manager_holder(md_collection_name, abstract_module)
          Module.new do
            extend ManagersHolder
            @abstract_module = abstract_module
            @md_collection_name = md_collection_name
          end
        end

        def self.init
          ABSTRACTS.each do |abstract_module|
            const_name = Module.new {extend abstract_module}.md_collection
            const_set const_name,
              build_manager_holder(const_name, abstract_module)
          end
        end

        def self.method_missing(method, **args)
          manager_holder = const_get method
          fail NoMethodError,
            "undefined method `#{method}' for #{self.name}" unless\
            manager_holder.respond_to? :manager_holder?
          manager_holder
        end

        init
      end

      # @todo rename AutoFixtures to ?
      # @example
      #  include MetaData::AutoFixtures
      #
      #  ref = auto_fixtures.Catalogs.CtalogName.ref Attr1: 'Value' do |item|
      #    item.Attr2 = 'Value2'
      #    item[:TabularSection].add Attr1: 'Value' do |tab_item|
      #      tab_item.Attr2 = 'Value2
      #    end
      #  end
      module AutoFixtures
        module ObjectBuilder
          class ObjectWrapper
            class TabularSection
              attr_reader :ole_ts
              def initialize(ole_ts)
                @ole_ts = ole_ts
              end

              def add(**values, &block)
                item = ole_ts.Add
                values.each do |k, v|
                  item.send("#{k}=", v)
                end
                yield item if block_given?
                item
              end
            end

            def tabular(name)
              TabularSection.new(ole_obj.send(name))
            end
            alias_method :[], :tabular

            attr_reader :ole_obj
            def initialize(ole_obj)
              @ole_obj = ole_obj
            end

            def method_missing(method, *args)
              ole_obj.send(method, *args)
            end
          end

          def wrapp_(ole)
            ObjectBuilder::ObjectWrapper.new(ole)
          end
          private :wrapp_

          def new(**attributes, &block)
            ow = wrapp_ new_object(**attributes)
            yield ow if block_given?
            ow.ole_obj
          end

          def make(**attributes, &block)
            ow = wrapp_ new(**attributes, &block)
            _write(ow.ole_obj)
            ow.ole_obj
          end

          def ref(**attributes, &block)
            make(**attributes, &block).Ref
          end

          # @todo implements refs finder
          def find(**attributes, &block)
            fail NotImplementedError
          end
        end

        module GroupedObjectBuilder
          include ObjectBuilder

          def g_new(**attributes, &block)
            ow = wrapp_ new_group **attributes
            yield ow if block_given?
            ow.ole_obj
          end

          def g_make(**attributes, &block)
            ow = wrapp_ g_new(**attributes, &block)
            _write ow.ole_obj
            ow.ole_obj
          end

          def g_ref(**attributes, &block)
            g_make(**attributes, &block).Ref
          end
        end

        module RegisterBuilder
          class Records
            attr_reader :ole_rs
            def initialize(ole_rs)
              @ole_rs = ole_rs
            end

            def add(**values, &block)
              rec = ole_rs.Add
              values.each do |k, v|
                rec.send("#{k}=", v)
              end
              yield rec if block_given?
              rec
            end
          end

          def records(**filter, &block)
            rs = record_set(**filter)
            yield Records.new(rs)
            rs.write false
            rs
          end
        end

        class FixtureFactory
          VALID_RUNTIMES = [:external, :thick]

          attr_reader :ole_runtime
          def initialize(ole_runtime)
            @ole_runtime = ole_runtime
            validate_ole_runtime_type?
          end

          def validate_ole_runtime_type?
            fail "Runtime must be :external or :thick" unless\
              VALID_RUNTIMES.include? self.ole_runtime.ole_type
          end

          def method_missing(method, *args)
            calls_stack << method
            return execute_stack if calls_stack.size == 2
            self
          end

          def execute_stack
            manager_name = calls_stack.shift
            md_name = calls_stack.shift
            manager = MetaData::Managers.send(manager_name).send(md_name)
            new_builder(mixin_get(manager_name), manager, ole_runtime)
          end

          def mixin_get(manager_name)
            case manager_name
            when :Catalogs then GroupedObjectBuilder
              # TODO: when ...
            when :InformationRegisters then RegisterBuilder
              # TODO: when ...
            else
              fail "Invalid manager_name `#{manager_name}'"
            end
          end

          def new_builder(mixin, manager, runtime)
            Class.new do
              like_ole_runtime runtime
              include manager
              include mixin
            end.new
          end

          def calls_stack
            @calls_stack ||= []
          end
        end

        def auto_fixtures
          MetaData::AutoFixtures::FixtureFactory.new ole_runtime_get
        end
      end
    end
  end
end
