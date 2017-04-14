module AssDevel
  module External
    require 'uuid'
    class Specification
      DEF_LANG = 'ru'

      module Types
        module Abstract
          attr_reader :spec
          def initialize(spec)
            @spec = spec
          end

          def uuid
            @uuid ||= UUID.new
          end

          def new_uuid
            uuid.generate
          end

          def ext
            'Abstract method call'
          end

          def new
            template
          end

          def template
            "\uFEFF<?xml version=\"1.0\" encoding=\"UTF-8\"?>\r\n"\
              "<MetaDataObject xmlns=\"http://v8.1c.ru/8.3/MDClasses\" xmlns:app=\"http://v8.1c.ru/8.2/managed-application/core\" xmlns:cfg=\"http://v8.1c.ru/8.1/data/enterprise/current-config\" xmlns:cmi=\"http://v8.1c.ru/8.2/managed-application/cmi\" xmlns:ent=\"http://v8.1c.ru/8.1/data/enterprise\" xmlns:lf=\"http://v8.1c.ru/8.2/managed-application/logform\" xmlns:style=\"http://v8.1c.ru/8.1/data/ui/style\" xmlns:sys=\"http://v8.1c.ru/8.1/data/ui/fonts/system\" xmlns:v8=\"http://v8.1c.ru/8.1/data/core\" xmlns:v8ui=\"http://v8.1c.ru/8.1/data/ui\" xmlns:web=\"http://v8.1c.ru/8.1/data/ui/colors/web\" xmlns:win=\"http://v8.1c.ru/8.1/data/ui/colors/windows\" xmlns:xen=\"http://v8.1c.ru/8.3/xcf/enums\" xmlns:xpr=\"http://v8.1c.ru/8.3/xcf/predef\" xmlns:xr=\"http://v8.1c.ru/8.3/xcf/readable\" xmlns:xs=\"http://www.w3.org/2001/XMLSchema\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" version=\"2.0\">\r\n"\
            "\t<External#{self.class::EXTERNAL_TYPE} uuid=\"#{new_uuid}\">\r\n"\
            "\t\t<InternalInfo>\r\n"\
            "\t\t\t<xr:ContainedObject>\r\n"\
            "\t\t\t\t<xr:ClassId>#{self.class::CLASS_ID}</xr:ClassId>\r\n"\
            "\t\t\t\t<xr:ObjectId>#{new_uuid}</xr:ObjectId>\r\n"\
            "\t\t\t</xr:ContainedObject>\r\n"\
            "\t\t\t<xr:GeneratedType name=\"External#{self.class::EXTERNAL_TYPE}Object.#{spec.Name}\" category=\"Object\">\r\n"\
            "\t\t\t\t<xr:TypeId>#{new_uuid}</xr:TypeId>\r\n"\
            "\t\t\t\t<xr:ValueId>#{new_uuid}</xr:ValueId>\r\n"\
            "\t\t\t</xr:GeneratedType>\r\n"\
            "\t\t</InternalInfo>\r\n"\
            "\t\t<Properties>\r\n"\
            "\t\t\t<Name>#{spec.Name}</Name>\r\n"\
            "\t\t\t<Synonym>\r\n"\
            "\t\t\t\t<v8:item>\r\n"\
            "\t\t\t\t\t<v8:lang>#{spec.lang}</v8:lang>\r\n"\
            "\t\t\t\t\t<v8:content>#{spec.Synonym}</v8:content>\r\n"\
            "\t\t\t\t</v8:item>\r\n"\
            "\t\t\t</Synonym>\r\n"\
            "\t\t\t<Comment>#{spec.Comment}</Comment>\r\n"\
            "\t\t\t<DefaultForm/>\r\n"\
            "\t\t\t<AuxiliaryForm/>#{self.class::EXTRAS}\r\n"\
            "\t\t</Properties>\r\n"\
            "\t\t<ChildObjects/>\r\n"\
            "\t</External#{self.class::EXTERNAL_TYPE}>\r\n"\
            "</MetaDataObject>\r\n"
          end

          def ole_manager
            raise 'Abstract method call'
          end
        end

        class Report
          include Abstract
          EXTERNAL_TYPE = 'Report'
          CLASS_ID = 'e41aff26-25cf-4bb6-b6c1-3f478a75f374'
          EXTRAS = "\n"\
                   "\t\t\t<MainDataCompositionSchema/>\n"\
                   "\t\t\t<DefaultSettingsForm/>\n"\
                   "\t\t\t<AuxiliarySettingsForm/>\n"\
                   "\t\t\t<DefaultVariantForm/>\n"\
                   "\t\t\t<VariantsStorage/>\n"\
                   "\t\t\t<SettingsStorage/>\n"

          def ext
            'erf'
          end

          def ole_manager
            :ExternalReports
          end
        end

        class Processor
          include Abstract
          EXTERNAL_TYPE = 'DataProcessor'
          CLASS_ID = 'c3831ec8-d8d5-4f93-8a22-f9bfae07327f'
          EXTRAS = ''

          def ext
            'epf'
          end

          def ole_manager
            :ExternalDataProcessors
          end
        end
      end

      attr_accessor :name, :platform_require, :src_root, :release_dir
      attr_accessor :name_space
      attr_reader :type
      attr_writer :app_requrements
      attr_writer :lang

      def initialize(type_cls)
        @type = type_cls.new(self)
      end

      def app_requrements
        @app_requrements ||= {}
      end

      def lang
        @lang ||= DEF_LANG
      end

      def src
        @src ||= Src.new(self)
      end

      attr_accessor :Name
      alias_method :name, :Name
      alias_method :name=, :Name=
      attr_accessor :Synonym
      attr_accessor :Comment
      attr_accessor :Version
      alias_method :version, :Version
    end

    class Src < Sources::Abstract::Src
      include Sources::HaveRootFile
      include Sources::DumperVersionWriter
      include Sources::Builded

      attr_reader :spec
      def initialize(spec)
        super spec.src_root
        @spec = spec
      end

      def self.ROOT_FILE
        "root.xml"
      end

      def init_src
        return if exists?
        FileUtils.mkdir_p src_root
        FileUtils.touch root_file
        File.open(root_file, 'w:utf-8', :bom => true) do |f|
          f.write(spec.type.new)
        end
        repo_add_to_index
      end

      def fail_operation_not_support(op)
        fail NotImplementedError, "Operation `#{op}' not support"

      end

      def dump
        fail_if_repo_not_clear
        fail 'Invalid build' unless build
        before_dump
        write_dumper_version build.platform_version
        build.dump_binry
        repo_add_to_index
      end

      def before_dump
        fail 'Src root not exists' unless exists?
        rm_rf!
      end
      private :before_dump

    end

    module Builds
      # Runtime for design and testing
      module InfoBaseBuilder
        # @api private
        class Template
          include AssLauncher::Api
          BUILD_DIR = '.infobase.builds'

          attr_reader :raw, :build
          def initialize(raw, build)
            @build = build
            @raw = raw
          end

          def options
            build.options.merge(platform_require: spec.platform_require)
          end

          def spec
            build.spec
          end

          def ib_name
            spec.name
          end

          def raw_conn_str
            begin
              cs raw.to_s
            rescue AssLauncher::Support::ConnectionString::ParseError
            end
          end

          def info_base_get
            return AssMaintainer::InfoBase
              .new(ib_name, raw_conn_str) if raw_conn_str
            AssTests::InfoBases::InfoBase
              .new(ib_name, conn_str, false, **options.merge(template: raw))
          end
          private :info_base_get

          def info_base
            @info_base ||= info_base_get
          end

          def conn_str
            return if raw_conn_str
            @conn_str ||= conn_str_get
          end

          def conn_str_get
            cs_file file: prepare_build_dir
          end
          private :conn_str_get

          def prepare_build_dir
            "#{build.build_path}.ib"
          end
          private :prepare_build_dir
        end
      end

      # Binary file of external object
      class BinFile < AssDevel::Builds::Abstract::FileBuild
        DEF_DIR = './binary.builds'

        attr_reader :app_template
        # @param app_template [String AssLauncher::Support::ConnectionString]
        #  if got connection string expected exists infobase
        #  otherwise infobase will be builded
        def initialize(app_template, key = nil, dir = nil, **options)
          super key, dir, **options
          @app_template = InfoBaseBuilder::Template.new(app_template, self)
        end

        def info_base
          app_template.info_base
        end

        def dir
          @dir || DEF_DIR
        end

        def platform_version
          info_base.thick.version
        end

        def build_
          return self if built?
          super
          build_binary
          self
        end

        def build_binary
          validate_application
          xml_file = src.root_file
          bin_file = build_path
          info_base.designer do
            loadExternalDataProcessorOrReportFromFiles xml_file, bin_file
          end.run.wait.result.verify!
        end
        private :build_binary

        def dump_binry
          validate_application
          xml_file = src.root_file
          bin_file = build_path
          info_base.designer do
            dumpExternalDataProcessorOrReportToFiles xml_file, bin_file do
              _Format :Hierarchical
            end
          end.run.wait.result.verify!
        end

        def validate_application
          app_name, app_version = app_name_verion_get
          spec.app_requrements.each do |name, requirement|
            fail "Invalid application `#{app_name}'" if app_name != name.to_s
            fail "Invalid application version `#{app_version}'" unless\
              Gem::Version::Requirement.new(requirement)
                .satisfied_by?(Gem::Version.new(app_version))
          end
        end

        def app_name_verion_get
          begin
            ext = info_base.ole(:external)
            ext.__open__ info_base.connection_string
            result = [ext.Metadata.Name, ext.Metadata.Version]
          ensure
            ext.__close__ if ext
          end
          result
        end

        def built?
          binary_built? && application_built?
        end

        def binary_built?
          File.exist?(build_path)
        end

        def application_built?
          info_base.exists?
        end

        def ext
          spec.type.ext
        end

        def rm!
          FileUtils.rm_f build_path if binary_built?
        end
      end
    end
  end
end
