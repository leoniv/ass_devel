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


  end
end
