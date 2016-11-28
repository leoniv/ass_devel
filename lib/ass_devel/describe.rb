module AssDevel
  module Describe
    # @api private
    module Mixins
      # @api private
      module MdDescriber
        # TODO

        def md_object
          @md_object || fail("Not initialized md container #{self.name}")
        end

        def is?(kalss)
          md_object.instance_of? kalss
        end

        def meta_data(name)
          @md_object = new_md_object(name)
          @md_object.container = self
          yield md_object if block_given?
        end

        def sources
          fail 'FIXME'
        end

        def self.extended(base)
          @app_src = base::APP_SRC
        end

        def app_src
          @app_src
        end
      end
    end

    module DynamicDsl
#      DSL = {subsytem: MetaData::MdObjects::Subsystem,
#             common_module: FIXME
#      }

      # TODO:
    end

    module Application
      module Configuration
        include Mixins::MdDescriber
        def new_md_object(name)
          fail 'FIXME'
#          MetaData::MdObjects::Configuration.new(name)
        end
      end

      module Block
        include Mixins::MdDescriber
        def new_md_object(name)
          fail 'FIXME'
#          MetaData::MdObjects::Subsystem.new(name, self::PREFIX)
        end
      end
    end

    module External
      module DataProcessor
        include Mixins::MdDescriber
        def new_md_object(name)
          fail 'FIXME'
#          MetaData::MdObjects::Externals::DataProcessor.new(name)
        end
      end

      module Report
        include Mixins::MdDescriber
        def new_md_object(name)
          fail 'FIXME'
#          MetaData::MdObjects::Externals::Report.new(name)
        end
      end
    end
  end
end
