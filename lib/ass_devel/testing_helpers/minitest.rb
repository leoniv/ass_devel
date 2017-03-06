module AssDevel
  module TestingHelpers
    module MetaData
      # Mixins for Minitest
      module Minitest
        # Add method #include_manager
        # wich make shortly include MetaData::Manager into {Minitest::Spec}
        # test case
        # @exmple
        #  describe 'Catalogs.CatalogName' do
        #    like_ole_runtime Runtimes::Ext
        #
        #    # It include module AssDevel::TestingHelpers::MetaData::Catalogs[:CatalogName]
        #    include_manager # Without arg use Spec.name.
        #    # If Spec.name not usable for recognize MetaData manager require passes argument
        #    include_manager 'Catalogs.CatalogName'
        #
        #    it '.foo' do
        #      catalog_manager.foo.must_equal 'bar'
        #    end
        #  end
        #
        module IncludeManager
          def md_name
            @md_name
          end

          def include_manager(md_name = name)
            return if @md_name
            @md_name = md_name
            include_manager_
          end
          private :include_manager

          def include_manager_
            include (eval "AssDevel::TestingHelpers::MetaData::Managers::#{md_name.split('.')[0]}")[md_name.split('.')[1]]
          end
          private :include_manager_
        end
      end
    end
  end
end

require 'minitest/spec'
# Monkey patch
module Minitest
  # @example (see AssDevel::MetaData::Minitest::IncludeManager)
  class Spec
    extend AssDevel::TestingHelpers::MetaData::Minitest::IncludeManager
  end
end
