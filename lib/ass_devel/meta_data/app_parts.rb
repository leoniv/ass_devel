module AssDevel
  module MetaData
    module AppParts
      class Block < Abstract::Subsystem
        class BadPrefix < StandardError; end

        module Subsystems
          class Functional < Abstract::Subsystem
            def initialize(name, block, **props)
              super name, '', block, **props
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
        end

        module Roles
          # @abstract
          class FunctionalRole < Abstract::Role
            'TODO:'
          end

          class ReadOnly < Abstract::Role
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
        end

        class RootModule < Abstract::MdObject
          include Mixins::CommonModule
          include MdContainer::TerminatedMdObject
          DEFAULT_PROPS = {FIXME: 'FIXME'}
          def initialize(subsytem)
            super "#{subsytem.prefix}_ROOT",subsytem.prefix,
              subsytem, **DEFAULT_PROPS
          end

          def good_owners
            [Block]
          end

          def root_get
            owner
          end

          def configuration_get
            owner.configuration
          end
        end

        def root_module
          @root_module ||= RootModule.new(self)
        end

        attr_accessor :app_src
        def initialize(prefix, app_src, **props)
          super "#{prefix}_BLOCK", prefix, nil, **props
          add_md_object(root_module)
          builds_roles
          self.app_src = app_src
        end

        def good_owners
          [Application::Configuration]
        end

        def read_only_role
          @read_only_role ||= Roles::ReadOnly.new(self)
        end

        def builds_roles
          add_md_object(read_only_role)
        end

        def good_children
          [RootModule,
           Roles::ReadOnly,
           Functional]
        end

        def IncludeInCommandInterface
          false
        end
      end

      class Configuration < Abstract::MdObject
        class PrefixCollision < StandardError; end

        module Roles
          # @abstract
          class ApplicationRole < Abstract::Role
            def initialize(app_block)
              super "#{app_block.prefix}_#{extract_name}",
                app_block.prefix, app_block,
                Synonym: I18N(self.class::SYN),
                Comment: I18N(self.class::COMM)
            end

            def extract_name
              self.class.name.split('::').last.to_s
            end
            private :extract_name

            def good_owners
              [Subsystems::AppBlock]
            end
          end

          class Admin < ApplicationRole
            SYN  = 'Application admin rights'
            COMM = SYN
            'TODO:'

          end

          class BaseUser < ApplicationRole
            SYN  = 'Application base user rights'
            COMM = SYN
            'TODO:'
          end

          class AdvancedUser < ApplicationRole
            SYN  = 'Application advanced user rights'
            COMM = SYN
            'TODO:'
          end

          class RunExternals < ApplicationRole
            SYN  = 'Application rights for opent exterlnals'
            COMM = "#{SYN} like a DataProcessor or Report"
            'TODO: интерактивное открытие вненшних обработок отчетов'
          end

          class SuperUser < ApplicationRole
            SYN = 'Super user rights'
            COMM = "#{SYN} aka AllRights"
            'TODO: ПолныеПрава'
          end
        end

        module Subsystems
          # @abstract
          class AppBlock < Block
            def good_owners
              [Configuration]
            end

            def good_children
              [Roles::Admin,
               Roles::BaseUser,
               Roles::AdvancedUser,
               Roles::RunExternals,
               Roles::SuperUser
              ]
            end

            def builds_roles
              good_children.each do |klass|
                add_md_object(klass.new(self))
              end
            end

            def IncludeInCommandInterface
              false
            end
          end
        end

        PROPS = {АвторскиеПрава: :Copyright,
                 АдресИнформацииОКонфигурации: :ConfigurationInformationAddress,
                 АдресИнформацииОПоставщике: :VendorInformationAddress,
                 АдресКаталогаОбновлений: :UpdateCatalogAddress,
                 Версия: :Version,
                 КраткаяИнформация: :BriefInformation,
                 ПодробнаяИнформация: :DetailedInformation}

        include Mixins::PropsToAccessor

        attr_accessor :app_src
        def initialize(name, app_src, **props)
          super name, '', nil, **props
          self.app_src = app_src
          add(app_block)
        end

        def app_block
          @app_block ||= Subsystems::AppBlock.new('APP', app_src) do |b|
            b.Synonym = Synonym
            b.Explanation = 'MAIN APPLICATION BLOCK'
          end
        end

        def blocks
          prefixes.values
        end

        # TODO: языки?

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

        def add(block)
          fail ArgumentError unless block.is_a? Block
          prefixes_add block.prefix, block
        end
      end

      class UiSection < Abstract::Subsystem
        module Subsystems
          class Subssection < Abstract::Subsystem
            'TODO:'
            def initialize(name, ui_section, **props)
              'UI_SECTION_NAME'
              fail 'FIXME'
            end


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

        module Roles
          class UiRole < Abstract::Role
            'TODO: просмотр для подситемы'
          end
        end

        def initialize(name, configuration, **props)
          'UI_NAME'
          fail 'FIXME'
        end

        'TODO:'
        def IncludeInCommandInterface
          true
        end

        def good_owners
          [Configuration]
        end

        def good_child?(child)
          child.is_a? Abstract::TopMdObject
        end
      end
    end
  end
end
