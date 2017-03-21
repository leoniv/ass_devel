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
        module Abstract
          module Wrapper
            attr_reader :ole, :gate_way
            def initialize(ole_obj, ole_runtime)
              @ole = ole_obj
              @gate_way = Class.new do
                like_ole_runtime ole_runtime
                include TestGateWay
              end.new
            end

            def method_missing(method, *args)
              ole.send(method, *args)
            end
          end

          module PrivateContext
            class Context
              attr_reader :wrapper
              def initialize(wrapper)
                @wrapper = wrapper
              end

              def method_missing(method, *args)
                wrapper.gate_way._test_gate_way(wrapper.ole, method, **to_hash(*args))
              end

              def to_hash(*args)
                r = {}
                args.each_with_index do |a, i|
                  r["arg_#{i}".to_sym] = a
                end
                r
              end
              private :to_hash
            end

            def private
              @private ||= Context.new(self)
            end
          end
        end

        # @todo (see Wrappers)
        module DSL
          def wrapp_form(form)
            ole = getForm(form) if form.is_a? ::String
            ole = form if form.is_a? ::WIN32OLE
            fail ArgumentError, 'Expected form name or WIN32OLE instance' unless\
              ole
            Wrappers::Form.new(ole, ole_runtime_get)
          end

          def wrapp_module(ole_module)
            Module.new(ole_module, ole_runtime_get)
          end
        end

        class Module
          include Abstract::Wrapper
          include Abstract::PrivateContext
        end

        class Form
          include Abstract::Wrapper
          module Context
            class Server < Abstract::PrivateContext::Context
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
                  stack.clear
                  r
                end
                private :name

                def get
                  context.wrapper.gate_way._test_property_get context.wrapper.ole, name
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

              # Call long form method like Items.ItemName.GetAction('action_name')
              def call(string, *args)
                wrapper.gate_way._test_eval_on_server(wrapper.ole, string, **to_hash(*args))
              end

              # Call short form method GetAction('action_name')
              def method_missing(method, *args)
                call(method.to_s, *args)
              end
            end

            class Client < Abstract::PrivateContext::Context; end
          end

          def self.method_missing(m, *a)
            split = m.to_s.split('_')
            fail NoMethodError, "undefined method `#{m}' for #{self.name}" if\
              split.shift != 'wrapp'
            _klass_(split).new(*a)
          end

          def self._klass_(split)
            eval split.map(&:capitalize).join('::')
          end
          private_class_method :_klass_

          def server
            Context::Server.new(self)
          end

          def client
            Context::Client.new(self)
          end

          module AbstractFormElementWrapper
            attr_reader :form_wrapper, :name
            def initialize(form_wrapper, name)
              @form_wrapper = form_wrapper
              @name = name.to_s
            end

            def ole
              fail 'Abstract method call'
            end

            def method_missing(m, *a)
              return ole.send(m, *a) if\
                m.to_s =~ %r{=\s+\z} or a.size > 0 or ole.ole_respond_to? m
              srv_prop_get(m)
            end

            def server
              form_wrapper.server
            end

            def client
              form_wrapper.client
            end
          end

          module Attribute

            def self.new(form_wrapper, name)
              attr_class(form_wrapper, name).new(form_wrapper, name)
            end

            def self.attr_class(form_wrapper, name)
              abs_attr = Attribute::Abstract.new(form_wrapper, name)
              return DynamicList if\
                abs_attr.ole.ole_respond_to? :QueryText
              return FormDataCollection if\
                (!abs_attr.ole.ole_respond_to?(:Property) && abs_attr.ole.ole_respond_to?(:Delete))
              return FormDataStructureAndCollection if\
                (abs_attr.ole.ole_respond_to?(:Property) && abs_attr.ole.ole_respond_to?(:Delete))
              return FormDataStructure if\
                (abs_attr.ole.ole_respond_to?(:Property) && !abs_attr.ole.ole_respond_to?(:Delete))
              return FormDataTree if\
                (abs_attr.ole.ole_respond_to? :GetItems)
              Generic
            end

            class Abstract
              include AbstractFormElementWrapper

              def ole
                @ole ||= ole_get
              end

              # If attribute is structure like Object.Property
              def ole_get
                r = form_wrapper
                name.split('.').each do |m|
                  break unless r.send(m).is_a? WIN32OLE
                  r = r.send(m)
                end
                r
              end
              private :ole_get

              def attr_srv_prop_get(attr_, prop)
                r = server.prop
                attr_.split('.').each do |m|
                  r = r.send(m)
                end
                r.send(prop).get
              end
              private :attr_srv_prop_get

              def srv_prop_get(prop)
                attr_srv_prop_get(name, prop)
              end
              alias_method :[], :srv_prop_get
            end

            class Generic < Abstract

            end

            class DynamicList < Abstract
              def rows_get(widget)
                fail NotImplementedError
              end
            end

            class FormDataCollection < Abstract
              class Row
                attr_reader :widget, :index
                def initialize(widget, index)
                  @index = index
                  @widget = widget
                end

                def method_missing(m, *args)
                  fail NoMethodError, m.to_s unless column(m)
                  get(column(name))
                end

                def column(name)
                  windget.column(name)
                end
                private :column

                def get(column)
                  ole.send(column.data_path.split('.').last)
                end
                private :get

                def ole
                  data_source.Get(index)
                end
              end

              def rows_get(widget)
                r = []
                Count().times do |index|
                  r << Row.new(widget, index)
                end
                r
              end
            end

            class FormDataStructureAndCollection < Abstract
              def rows_get(widget)
                fail NotImplementedError
              end
            end

            class FormDataStructure < Abstract

            end

            class FormDataTree < Abstract
              def rows_get(widget)
                fail NotImplementedError
              end
            end
          end

          # Define of 1C ManagedForm Widgets wrappers
          # Winget class hase name restriction. Name of class mustn't be
          # cammel-case. Class name +FormField+ is wrong but +Formfield+ is
          # good. Restriction caused by dinamicaly generated {Form}
          # interface. {Form.method_missing} translate +wrapp_*+ methods to a
          # class name, example +Form.wrapp_widget_formfield+ or
          # +Form.wrapp_(:widget_formfield+ returns {Form::Widgets::Formfield}
          # instance. See also {Form._klass_}
          # @example
          #   describe 'CommonForms.FormName' do
          #     like_ole_runtime Thin
          #     include AssDevel::TestingHelpers::TestGateWay::Wrappers::DSL
          #
          #     def form
          #       @form ||= wrapp_form(getForm('CommonForm.FormName)
          #     end
          #
          #     it 'Clik button' do
          #       form.wrapp_(:widget_button, :ButtonName).click
          #     end
          #
          #     it 'ClienList binds with the correct data source' do
          #       form.wrapp_(:widget_formtable, :ClientsList)
          #         .data_path.must_equal 'ClientsDinamycalyList'
          #     end
          #   end
          module Widget
            module Abstract
              module Item
                include AbstractFormElementWrapper

                def ole
                  @ole ||= form_wrapper.Items.send(name)
                end

                def item_srv_prop_get(item, prop)
                  server.prop.Items.send(item).send(prop).get
                end
                private :item_srv_prop_get

                def srv_prop_get(prop)
                  item_srv_prop_get(name, prop)
                end
              end

              module ItHas
                module DataPath
                  def data_path
                    srv_prop_get :DataPath
                  end

                  def data_source
                    form_wrapper.attribute(data_path)
                  end
                end

                module GetAction
                  def get_action(action)
                    server.call("Items.#{name}.GetAction", action.to_s)
                  end

                  def exec_action(action, *args)
                    client.send(get_action(action), *args)
                  end
                end
              end
            end

            class Formfield
              include Abstract::Item
              include Abstract::ItHas::DataPath
              include Abstract::ItHas::GetAction
            end

            class Formtable
              include Abstract::Item
              include Abstract::ItHas::DataPath
              include Abstract::ItHas::GetAction

              # All +FormField+ type's table fields
              def fields
                @fields ||= fields_get
              end

              def fields_get
                r = []
                ole.ChildItems.each do |item|
                  r << form_wrapper.widget(:formfield, item.Name) if\
                    item.ole_respond_to?(:WarningOnEditRepresentation)
                end
                r
              end
              private :fields_get

              # All table fields releted with {#data_path}
              def columns
                fields.select do |f|
                  f.data_path =~ %r{#{data_path.gsub('.','\.')}\.\S+}
                end
              end

              def column(coll)
                columns.find do |f|
                  f.Name =~ %r{\A#{coll}\z}i
                end
              end
              alias_method :[], :column

              def rows
                @rows ||= data_source.rows_get(self)
              end

              def count
                data_source.Count
              end
            end

            class Button
              include Abstract::Item

              def method
                command.Action
              end

              def click
                client.send(method, command)
              end

              def command
                form_wrapper.Commands.Find(commandName)
              end
            end
          end

          # Dinamicaly generate Wrappers::Form*
          # We cant't use +#method_missing+ because +#method_missing+
          # forward messages into {#ole} object
          # @exmple
          #   form.wrapp_(:widget_button, :ButtonName).click
          def wrapp_(what, *args)
            AssDevel::TestingHelpers::TestGateWay::Wrappers::Form
              .send("wrapp_#{what}", *args.unshift(self))
          end

          # Dinamicaly generate Wrappers::Form::Widgets*
          # @exaple
          #   form.widget(:button, :ButtonName).click
          def widget(what, name)
            wrapp_("widget_#{what}".to_sym, name)
          end

          # Dinamicaly generate Wrappers::Form::Widgets*
          # @exaple
          #   form.widget.button.ButtonName.click
          def widgets
            Class.new do
              def initialize(form)
                @form = form
              end

              def stack
                @stack ||= []
              end

              def method_missing(m, *a)
                stack << m
                execute
              end

              def execute
                return self if stack.size < 2
                @form.widget(*stack)
              end
            end.new(self)
          end

          # Click on button
          # @exaple
          #  form.click(:ButtonName)
          def click(button)
            widgets.button.send(button).click
          end

          # Set form attributes
          def set(**attributes, &block)
            attributes.each do |k, v|
              ole.send("#{k}=", v)
            end
            yield self if block_given?
          end

          # @return attribute wrapper
          def attribute(name)
            Attribute.new(self, name)
          end
          alias_method :[], :attribute

          # @example
          #  form.attributes.AttrName #=> wrapper
          def attributes
            Class.new do
              def initialize(form)
                @form = form
              end

              def stack
                @stack ||= []
              end

              def method_missing(m, *a)
                stack << m
                execute
              end

              def execute
                return self if stack.size < 1
                @form.attribute(stack.shift)
              end
            end.new(self)
          end
          alias_method :atr, :attributes
        end
      end
    end

    # Provides dynamically generated mixins-helpers
    # @example
    #
    #  describe 'Tests for Catalogs.CatalogName' do
    #    like_ole_runtime Runtimes::Ext
    #    include AssDevel::TestingHelpers::MetaData::Managers::Catalogs[:CatalogName]
    #
    #    def catalog_item
    #      new_item Description: 'Foo' do |obj|
    #        obj.attr1 = 'bar'
    #      end
    #    end
    #
    #    it 'Item method #foo' do
    #       catalog_item.foo.must_equal 'foo'
    #    end
    #
    #    it 'ManagerModule method #bar' do
    #      catalog_manager.bar.must_equal 'bar'
    #    end
    #  end
    module MetaData
      module Managers
        # @todo add DocumentManger, TaskManger etc.
        module Abstract
          module AbstractObjectManager
            include AssOle::Snippets::Shared::Query
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

            def find_objects(*args, **options, &block)
              fail 'Abstract method call'
            end

            def qtext_condition_(**options)
              qtext = ''
              options.keys.each_with_index do |key, index|
                op = index != 0 ? 'and' : ''
                qtext << "#{op} ref.#{key} = &#{key}\n"
              end
              qtext
            end
            private :qtext_condition_

            def ole_to_arr_(ole_arr)
              r = []
              ole_arr.each do |i|
                r << i
              end
              r
            end
            private :ole_to_arr_
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

            def find_objects(is_folder = false, **options, &block)
              qtext = "Select T.ref as ref from\n"\
                " Catalog.#{self.MD_NAME} as T\n where \n"

              options[:IsFolder] = is_folder if object_metadata.Hierarchical

              qtext << qtext_condition_(**options)

              arr = ole_to_arr_(query(qtext, **options)
                .Execute.Unload.UnloadColumn('ref'))
              return if arr.empty?
              return yield arr if block_given?
              arr
            end
          end

          module DocumentManger
            include AbstractObjectManager

            def md_collection
              :Documents
            end

            def _new_object_method
              :CreateDocument
            end

            alias_method :document_manager, :objects_manager
            alias_method :document_metadata, :object_metadata
            alias_method :new_doc, :new_object
            alias_method :make_doc, :make_object

            def post_(doc)
              doc.write(documentWriteMode.Posting)
            end

            def undo_post_(doc)
              doc.write(documentWriteMode.UndoPosting)
            end

            # @todo find document per +date_period+ in
            #  period Metadata.NumberPeriodicity
            def find_objects(**options, &block)
              qtext = "Select T.ref as ref from\n"\
                " Document.#{self.MD_NAME} as T\n where \n"

              qtext << qtext_condition_(**options)

              arr = ole_to_arr_(query(qtext, **options)
                .Execute.Unload.UnloadColumn('ref'))
              return if arr.empty?
              return yield arr if block_given?
              arr
            end
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

          module ExternalDataProcessorManager
            def md_collection
              :ExternalDataProcessors
            end

            def external_object
              send(md_collection).Create(self.MD_NAME)
            end

            def external_connect(path, safe_mode = false)
              external_object_path = AssLauncher::Support::Platforms
                .path(path.to_s).realpath

              dd = ole_connector
                .newObject('BinaryData', external_object_path.win_string)

              link = ole_connector.putToTempStorage(dd)

              ole_connector.send(md_collection)
                .connect(link, self.MD_NAME, safe_mode)
            end
          end

          module ExternalReportManager
            include ExternalDataProcessorManager
            def md_collection
              :ExternalReports
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

        def self.method_missing(method, *args)
          manager_holder = const_get method
          fail NoMethodError,
            "undefined method `#{method}' for #{self.name}" unless\
            manager_holder.respond_to? :manager_holder?
          manager_holder
        end

        init
      end

      # @example
      #  include MetaData::ObjectFactory
      #
      #  ref = object_factory.Catalogs.CtalogName.ref Attr1: 'Value' do |item|
      #    item.Attr2 = 'Value2'
      #    item[:TabularSection].add Attr1: 'Value' do |tab_item|
      #      tab_item.Attr2 = 'Value2
      #    end
      #  end
      module ObjectFactory
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

          # Find object.
          # @param atgs array of suitable arguments for +find_objects+
          # @param attributes hash of suitable attributes for +find_objects+
          # @raise RuntimeError if many objects whas found
          # @return [nil WIN32OLE] usually found WIN32OLE ref type object like
          #  DocumentRef, CatalogRef, etc
          def find(*args, **attributes, &block)
            arr = find_objects(*args, **attributes, &block)
            fail "Too many objects found #{args}, #{attributes}" if\
              arr.is_a?(Array) && arr.size > 1
              return arr[0] if arr.is_a?(Array)
              arr
          end

          # Find object per +find_attributes+ and call +what_do+ uless object
          # found. Block will be passed indo +what_do+ method. +args+ is
          # suitable for {#find} method +args+ array.
          # @param what_do [Symbol] method name :make, :new, :ref
          def find_or_do(what_do, *args, **find_attributes, &block)
            find(*args, **find_attributes) || send(what_do, **find_attributes, &block)
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

        class Dispatcher
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
            when :Documents then ObjectBuilder
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

        def object_factory
          MetaData::ObjectFactory::Dispatcher.new ole_runtime_get
        end
      end
    end

    # Mixin provaide 2 methods
    # for covert 1C valuses to/from string internal
    #
    # 1C method +ValueFromStringInternal+ and +ValueToStringInternal+
    # defined for server context only.
    #
    # For convert values on client require make CommomModule
    # wich define 2 wrappers for client +value_to_string_internal(obj)+
    # and +value_from_string_internal(obj)+
    #
    # After CommomModule made, define monkey patch of this module
    # on your +test_helper.rb+ wich owrload method `#testing_helper_module` and
    # returns suitable module
    #
    # @example
    #  # Monkey patch of #testing_helper_module
    #  module AssDevel
    #    module TestingHelpers
    #      module StringInternal
    #        def testing_helper_module
    #          cORE_TestHelper
    #        end
    #      end
    #    end
    #  end
    #
    module StringInternal
      SRV_RUNTIMES = [:thick, :external]
      def from_string_internal(string)
        if SRV_RUNTIMES.include? ole_runtime_get.ole_type
          return valueFromStringInternal string
        end
        testing_helper_module.value_from_string_internal(string)
      end

      def to_string_internal(value)
        if SRV_RUNTIMES.include? ole_runtime_get.ole_type
          return valueToStringInternal value
        end
        testing_helper_module.value_to_string_internal value
      end

      # (see StringInternal)
      def testing_helper_module
        fail 'Define monkey patch of this method'
      end
      private :testing_helper_module
    end

    # Provades helpers {Fixtures} for filling infobase of testing datata,
    # {Proxy} converts values beetween client and server
    # @todo require documented but unly example for memory
    #
    # @example
    #  module MySharedFixture
    #    extend AssDevel::TestingHelpers::RuntimesBridge::DSL
    #    define_fixtures Runtimes::Ext
    #
    #    def preapare_fixt
    #      fixt_let(:company1, :ref_delete) do |factory, fixtures, srv_ole|
    #        factory.Catalogs.Companies.ref do |ref|
    #          ref.Description = 'company1'
    #        end
    #      end
    #
    #      fixt_let(:company2, :ref_delete) do |factory, fixtures, srv_ole|
    #        factory.Catalogs.Companies.ref do |ref|
    #          ref.Description = 'company2'
    #          ref.Holder = fixtures.company1
    #          ref.Type = srv_ole.Enums.CompanyTypes.Holding
    #        end
    #      end
    #    end
    #
    #    def remove_fixt
    #      fixt_rm_all
    #    end
    #  end
    #
    #  module TestCase
    #    describe 'do in external runtime' do
    #      like_ole_runtime Runtimes::Ext
    #      include MySharedFixture
    #      include AssDevel::TestingHelpers::MetaData::Catalogs[:Companies]
    #      include AssTests::Minitest::Assertion
    #
    #      before do
    #        preapare_fixt
    #      end
    #
    #      after do
    #        remove_fixt
    #      end
    #
    #      it '#find_by_name' do
    #        _assert_equal fixtures.company1,
    #           catalog_manager.find_by_name('company1')
    #      end
    #
    #      it '#holder' do
    #        _assert_equal fixt_let[:company2], fixtures.company1.holder
    #      end
    #    end
    #  end
    #
    #
    module RuntimesBridge
      class Proxy
        require 'date'
        SIMPLE_TYPES = [String, Fixnum, Float, TrueClass, FalseClass, Time]
        attr_reader :real_runtime, :srv_runtime
        def initialize(srv_runtime, real_runtime)
          @real_runtime = Module.new do
            like_ole_runtime real_runtime
            extend StringInternal
          end
          @srv_runtime = Module.new do
            like_ole_runtime srv_runtime
            extend StringInternal
          end
        end

        def to_real(srv_value)
          return srv_value if SIMPLE_TYPES.include? srv_value.class
          fail ArgumentError unless srv_value.is_a? WIN32OLE
          real_runtime.from_string_internal\
            srv_runtime.to_string_internal(srv_value)
        end

        def to_srv(real_value)
          return real_value if SIMPLE_TYPES.include? real_value.class
          fail ArgumentError unless real_value.is_a? WIN32OLE
          srv_runtime.from_string_internal\
            real_runtime.to_string_internal(real_value)
        end

        def runtimes_equal?
          real_runtime.send(:ole_runtime_get) ==\
            srv_runtime.send(:ole_runtime_get)
        end
      end

      module RuntimeClones
        def self.new(ole_runtime, user, pass = nil)
          clones.find {|cl| cl.ole_runtime == ole_runtime && cl.user == user} ||\
            Clone.new(ole_runtime, user, pass)
        end

        def self.clones
          @clones ||= []
        end

        class Clone
          include AssLauncher::Api

          attr_reader :ole_runtime, :user, :pass
          def initialize(ole_runtime, user, pass = nil)
            @ole_runtime = ole_runtime
            @user = user
            @pass = pass
            RuntimeClones.clones << self
          end

          def clone
            ole_type = ole_runtime.ole_type
            @clone ||= Module.new do
              is_ole_runtime ole_type
            end
          end

          def run
            clone.run infobase
          end

          def stop
            clone.stop
          end

          def infobase
            @infobase ||= AssTests::InfoBases::InfoBase
              .new("clone#{hash}", conn_str, platform_require: platform_require)
          end

          def platform_require
            @platform_require ||= "= #{app_version}"
          end

          def app_version
            ole_runtime.ole_connector.newObject('SystemInfo').AppVersion
          end

          def conn_str
            @conn_str || conn_str_get
          end

          def conn_str_get
            r = cs(ole_runtime.ole_connector.InfoBaseConnectionString)
            r.usr = user
            r.pwd = pass
            r
          end
        end
      end

      def self.proxy(srv_runtime, real_runtime)
        Proxy.new(srv_runtime, real_runtime)
      end

      # Object for filling/remove test data to/from infobase
      # Also it provides access to created objects
      class Fixtures
        # @api private
        # Registers RecordSet eraser
        class RegisterRecordSet
          class Record
            attr_reader :record_set, :ole_record
            def initialize(record_set, ole_record)
              @record_set = record_set
              @ole_record = ole_record
            end

            def filter
              r = {}
              record_set.full_key.each do |key|
                r[key] = ole_record.send(key)
              end
              r
            end

            def ole_record_set
              rs = record_set.register_manager.CreateRecordSet
              filter.each do |k, v|
                rs.Filter.send(k).Set(v, true) unless v.nil?
              end
              rs
            end

            def rm
              ole_record_set.write
            end
          end

          REG_COLLECTIONS = [ :InformationRegisters,
                              :AccountingRegisters,
                              :AccumulationRegisters,
                              :CalculationRegisters ]

          attr_reader :ole_rs, :ole_runtime
          def initialize(ole_runtime, ole_rs)
            @ole_runtime = ole_runtime
            @ole_rs = ole_rs
          end

          def ole_connector
            ole_runtime.ole_connector
          end

          def md
            ole_rs.Metadata
          end

          def register_manager
            ole_connector.send(collection).send(md.Name)
          end

          def collection
            REG_COLLECTIONS.find do |coll|
              coll = AssDevel::MetaData::Const::MdCollections.get(coll)
              md_class?(coll)
            end
          end

          def md_class?(coll)
            coll.md_class.en == md_class || coll.md_class.ru == md_class
          end

          def md_class
            md.FullName.split('.')[0].to_sym
          end

          def record_key
            @record_key ||= register_manager.CreateRecordKey(structure)
          end

          def structure
            ole_connector.newObject('structure')
          end

          def record_key_fields
            [:Period, :Recorder, :LineNumber].select do |k|
              record_key.ole_respond_to? k
            end
          end

          def dimensions
            r = []
            md.Dimensions.each do |d|
              r << d.Name.to_sym
            end
            r
          end

          def full_key
            record_key_fields + dimensions
          end

          def rm
            ole_rs.each do |r|
              Record.new(self, r).rm
            end
            ole_rs.Clear
          end
        end

        DEF_TEARDOWNS_DO = {
          ref_delete: ->(ref, ole_runtime) { ref.GetObject.Delete if ref.GetObject },
          object_delete: ->(obj, ole_runtime) { obj.Delete if obj },
          record_set_delete: ->(rs, ole_runtime) {
            RegisterRecordSet.new(ole_runtime, rs).rm
          },
          nop: ->(obj, ole_runtime) {}
        }

        attr_reader :proxy, :object_factory
        def initialize(proxy)
          @proxy = proxy
          @object_factory = MetaData::ObjectFactory::Dispatcher.new\
            proxy.srv_runtime.ole_runtime_get
        end

        def srv_values
          @srv_values ||= {}
        end

        def yields?
          @yields || false
        end

        def yields(name, &block)
          @yields = true
          srv_values[name] = yield object_factory, self,
            self.srv_ole_runtime.ole_connector
        ensure
          @yields = false
        end

        def fixture_make(name, teardown_do, &block)
          yields(name, &block)
          teardowns_set(name, teardown_do)
          _define_method name
        end
        private :fixture_make

        def add(name, teardown_do, &block)
          fail ArgumentError unless block_given?
          fail ArgumentError unless name.respond_to? :to_sym
          fail "Transaction is active" if\
            proxy.srv_runtime.transactionActive
          fixture_make(name.to_sym, teardown_do, &block)
          send(name)
        end
        private :add

        def fixture_defined?(name)
          srv_values.key? name.to_sym
        end

        # Build fixture object. Define method +name+. Object builds only onse
        # and returns always they unless {#teardown} not called
        #
        # @param name [Symbol] fixture name
        # @param teardown_do [Proc Symbol] block which destroy fixture
        #   in to block will be passed srv_runtime object for destroy.
        #   If +Symbol+ given will be used {DEF_TEARDOWNS_DO} proc
        #
        # @example
        #   # Builds new fixture with defaults +teardown_do+ proc
        #   fixtures.let :foo_ref, :ref_delete do |factory|
        #     factory.Catalogs.Foo.ref do |item|
        #       item.Description = 'Foo name'
        #     end
        #   end # => WIN32OLE <:hash>
        #
        #   fixtures.let :foo_ref # => WIN32OLE <:hash>
        #
        #   fixtures.teardown_all # => nil
        #
        # @yield [MetaData::ObjectFactory::Dispatcher] fixture builder
        # @yield self
        # @return [WIN32OLE] object maked in srv_runtime and converted to
        #   real_runtime WIN32OLE object
        def let(name, teardown_do = nil, &block)
          return send(name) if fixture_defined? name
          add(name, teardown_do, &block)
        end
        alias_method :setup, :let

        def real_value(method)
          return srv_values[method] if yields?
          return srv_values[method] if proxy.runtimes_equal?
          proxy.to_real srv_values[method]
        end
        private :real_value

        def teardown(name, &block)
          return auto_teardown name unless block_given?
          _teardown(name, &block)
        end
        alias_method :rm, :teardown

        def teardown_all
          fail "Auto teardown all fixtures unpossible" unless auto_teardown_all?
          srv_values.keys.each do |name|
            auto_teardown name
          end
        end
        alias_method :rm_all, :teardown_all

        def auto_teardown(name)
          fail ArgumentError, "Teardown fixture `#{name}' not found" unless\
            teardowns_get name
          _teardown(name, &teardowns_get(name))
        end
        private :auto_teardown

        def _undefine_method(name)
          singleton_class.send :undef_method, name
          nil
        end
        private :_undefine_method

        def _define_method(name)
          singleton_class.send :define_method, name do
            real_value name
          end
          nil
        end
        private :_define_method

        def fixture_rm(name)
          _undefine_method(name)
          srv_values.delete name
          nil
        end
        private :fixture_rm

        def _teardown(name, &block)
#          fail ArgumentError,
#            "Fixture `#{name}' not found" unless fixture_defined? name
          return unless fixture_defined? name
          yield srv_values[name], proxy.srv_runtime.ole_runtime_get
          fixture_rm name
        end
        private :_teardown

        def teardowns_do
          @teardowns_do ||= {}
        end
        private :teardowns_do

        def teardowns_get(name)
          teardowns_do[srv_values[name]]
        end
        private :teardowns_get

        def teardowns_set(name, teardown_do_)
          teardown_do = teardown_do_detect(teardown_do_)
          fail ArgumentError, "teardown_do mast be a Proc" if\
            !teardown_do.nil? && !teardown_do.is_a?(Proc)
          if Proxy::SIMPLE_TYPES.include? srv_values[name].class
            teardowns_do[srv_values[name]] = teardown_do_detect(:nop)
          else
            teardowns_do[srv_values[name]] = teardown_do
          end
        end
        private :teardowns_set

        def teardown_do_detect(teardown_do)
          return DEF_TEARDOWNS_DO.fetch(teardown_do) if teardown_do.is_a? Symbol
          teardown_do
        end
        private :teardown_do_detect

        def auto_teardown_all?
          teardowns_do.values.compact.size ==\
            teardowns_do.values.size
        end
        private :auto_teardown_all?

        # Helper for remove real runtime objects
        def rm_real(value, teardown_do = nil, &block)
          return _rm_real(value, &block) if block_given?
          fail ArgumentError, "Invalid teardown_do #{teardown_do}" unless\
            teardown_do_detect(teardown_do).is_a? Proc
          _rm_real(value, &teardown_do_detect(teardown_do))
        end

        def _rm_real(value, &block)
          yield to_srv_value(value)
        end
        private :_rm_real

        def to_srv_value(real_value)
          return real_value if proxy.runtimes_equal?
          proxy.to_srv real_value
        end

        def srv_ole_runtime
          proxy.srv_runtime.ole_runtime_get
        end

        def at_server_do(caller_, *args, &block)
          args_ = *args.map {|a| proxy.to_srv a}
          begin
            caller_old_runtime = switch_ole_runtime(caller_.class, srv_ole_runtime)
            fixtures_old_runtime = switch_fixtures_runtime(caller_, srv_ole_runtime)
            yields_at_serever *args_, &block
          ensure
            switch_ole_runtime(caller_.class, caller_old_runtime)
            switch_fixtures_runtime(caller_, fixtures_old_runtime)
          end
        end

        def switch_fixtures_runtime(caller_, new_runtime)
          switch_ole_runtime caller_.fixtures.proxy.real_runtime, new_runtime
        end

        def switch_ole_runtime(runtimed, new_runtime)
          old_runtime = runtimed.ole_runtime_get
          runtimed.like_ole_runtime new_runtime
          old_runtime
        end
        private :switch_ole_runtime

        def yields_at_serever(*args, &block)
          yield *args
        end
        private :yields_at_serever
      end

      def self.fixtures(srv_runtime, real_runtime)
        Fixtures.new(proxy(srv_runtime, real_runtime))
      end

      # @api public
      module DSL
        def define_fixtures(srv_runtime)
          fail "#{srv_runtime} must be runned" unless srv_runtime.runned?

          define_method :fixtures do
            @fixtures ||= TestingHelpers::RuntimesBridge
              .fixtures(srv_runtime, ole_runtime_get)
          end

          define_method :fixt_let do |name, teardown_do = nil, &block|
            fixtures.let(name, teardown_do, &block)
          end

          define_method :fixt_rm do |name, &block|
            fixtures.rm(name, &block)
          end

          define_method :fixt_rm_all do
            fixtures.rm_all
          end

          define_method :fixt_rm_real do |real_value, teardown_do = nil, &block|
            fixtures.rm_real real_value, teardown_do, &block
          end

          define_method :at_server do |*args, &block|
            fixtures.at_server_do self, *args, &block
          end

          define_method :connect_as do |user, *args, &block|
            begin
              clone = RuntimeClones.new(ole_runtime_get, user)
              clone.run
              args_ = args.map {|a| fixtures.proxy.to_srv a}
              self.class.like_ole_runtime clone.clone
              fixtures.proxy.real_runtime.like_ole_runtime clone.clone
              args_ = args_.map {|a| fixtures.proxy.to_real a}
              block.yield *args_
            ensure
              if clone
                clone.stop
                fixtures.proxy.real_runtime.like_ole_runtime clone.ole_runtime
                self.class.like_ole_runtime clone.ole_runtime
              end
            end
          end

          define_method :connect_with do |roles, *args, &block|
            user = :"user_connect_with_#{roles.hash.abs}"
            at_server do
              fixt_let(user, :object_delete) do
                u = infoBaseUsers.CreateUser
                u.Name = "#{user}"
                u.FullName = "Fake User #{user}"
                roles.each do |r|
                  u.Roles.Add metaData.Roles.send(r)
                end
                u.Write
                u
              end
            end
            begin
              connect_as(user, *args, &block)
            ensure
              fixtures.rm user if fixtures.respond_to? user
            end
          end
        end
      end
    end
  end
end
