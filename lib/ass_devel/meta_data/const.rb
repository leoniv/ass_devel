module AssDevel
  module MetaData
    module Const
      module HaveContent
        def content
          @content ||= []
        end

        def get(en_ru)
          content.select {|r| r.en == en_ru.to_sym || r.ru == en_ru.to_sym}[0]
        end

        def klass
          fail 'Abstract method call'
        end

        def add(*args)
          r = klass.new(*args, self)
          const_set r.en, r
          content << r
          yield r if block_given?
        end
      end

      class RuEnNamed
        attr_accessor :en, :ru, :module_
        def initialize(en, ru, module_)
          self.en = en.to_sym
          self.ru = ru.to_sym
          self.module_ = module_
          self.class.instances << self
        end

        def const_name
          "#{module_}::#{en}"
        end

        def self.instances
          @instances ||= []
        end
      end

      module IncludedInMdClass
        # @return [Arry <MdClasses::MdClass>]
        def included_in_md_classes
          MdClasses.content.select do |md_class|
            md_class.all_included.include? self
          end
        end
      end

      module Modules
        extend HaveContent
        class BslModule < RuEnNamed
          include IncludedInMdClass
          def file_name
            "#{en}.bsl"
          end
        end

        def self.klass
          BslModule
        end

        add :ExternalConnectionModule, :МодульВнешнегоСоединения
        add :OrdinaryApplicationModule, :МодульОбычногоПриложения
        add :SessionModule, :МодульСеанса
        add :ManagedApplicationModule, :МодульУправляемогоПриложения
        add :Module, :Модуль
        add :ManagerModule, :МодульМенеджера
        add :ObjectModule, :МодульОбъекта
        add :CommandModule, :МодульКоманды
        add :ValueManagerModule, :МодульМенеджераЗначения
        add :RecordSetModule, :МодульНабораЗаписей
      end

      module Rights
        class Right < RuEnNamed
          include IncludedInMdClass
        end
        extend HaveContent

        def self.klass
          Right
        end

        add :Read, :Чтение
        add :Insert, :Добавление
        add :Update, :Изменение
        add :Delete, :Удаление
        add :Posting, :Проведение
        add :UndoPosting, :ОтменаПроведения
        add :View, :Просмотр
        add :InteractiveInsert, :ИнтерактивноеДобавление
        add :Edit, :Редактирование
        add :InteractiveSetDeletionMark, :ИнтерактивнаяПометкаУдаления
        add :InteractiveClearDeletionMark, :ИнтерактивноеСнятиеПометкиУдаления
        add :InteractiveDeleteMarked, :ИнтерактивноеУдалениеПомеченных
        add :InteractivePosting, :ИнтерактивноеПроведение
        add :InteractivePostingRegular, :ИнтерактивноеПроведениеНеОперативное
        add :InteractiveUndoPosting, :ИнтерактивнаяОтменаПроведения
        add :InteractiveChangeOfPosted, :ИнтерактивноеИзменениеПроведенных
        add :InputByString, :ВводПоСтроке
        add :TotalsControl, :УправлениеИтогами
        add :Use, :Использование
        add :InteractiveDelete, :ИнтерактивноеУдаление
        add :Administration, :Администрирование
        add :DataAdministration, :АдминистрированиеДанных
        add :ExclusiveMode, :МонопольныйРежим
        add :ActiveUsers, :АктивныеПользователи
        add :EventLog, :ЖурналРегистрации
        add :ExternalConnection, :ВнешнееСоединение
        add :Automation, :Automation
        add :InteractiveOpenExtDataProcessors, :ИнтерактивноеОткрытиеВнешнихОбработок
        add :InteractiveOpenExtReports, :ИнтерактивноеОткрытиеВнешнихОтчетов
        add :Get, :Получение
        add :Set, :Установка
        add :InteractiveActivate, :ИнтерактивнаяАктивация
        add :Start, :Старт
        add :InteractiveStart, :ИнтерактивныйСтарт
        add :Execute, :Выполнение
        add :InteractiveExecute, :ИнтерактивноеВыполнение
        add :Output, :Вывод
        add :UpdateDataBaseConfiguration, :ОбновлениеКонфигурацииБазыДанных
        add :ThinClient, :ТонкийКлиент
        add :WebClient, :ВебКлиент
        add :ThickClient, :ТолстыйКлиент
        add :AllFunctionsMode, :РежимВсеФункции
        add :SaveUserData, :СохранениеДанныхПользователя
        add :StandardAuthenticationChange, :ИзменениеСтандартнойАутентификации
        add :SessionStandardAuthenticationChange,
          :ИзменениеСтандартнойАутентификацииСеанса
        add :SessionOSAuthenticationChange,
          :ИзменениеАутентификацииОССеанса
        add :InteractiveDeletePredefinedData,
          :ИнтерактивноеУдалениеПредопределенныхДанных
        add :InteractiveSetDeletionMarkPredefinedData,
          :ИнтерактивнаяПометкаУдаленияПредопределенныхДанных
        add :InteractiveClearDeletionMarkPredefinedData,
          :ИнтерактивноеСнятиеПометкиУдаленияПредопределенныхДанных
        add :InteractiveDeleteMarkedPredefinedData,
          :ИнтерактивноеУдалениеПомеченныхПредопределенныхДанных
        add :ConfigExtensionsAdministration,
          :АдминистрированиеРасширенийКонфигурации
      end

      module PropTypes
        extend HaveContent

        module Classes
          def self.new(en, ru, module_)
            eval("self::#{en}").new(en, ru, module_)
          end
          class Abstract < RuEnNamed
            def initialize(en, ru, module_)
              super en, ru, module_
            end

            def valid?(string)
              fail 'Abstract'
            end

            def self.en_ru(en, ru)
              RuEnNamed.new(en, ru, self)
            end

            class Enum < Abstract
              class Item < RuEnNamed; end
              def self.klass
                Item
              end
              extend HaveContent

              def content
                self.class.content
              end

              def valid?(string)
                !self.class.get(string).nil?
              end
            end
          end

          class String < Abstract
            def valid?(s)
              s.is_a? ::String
            end
          end

          class Boolean < Abstract
            def valid?(bool)
              bool.is_a?(TrueClass) || bool.is_a?(FalseClass)
            end
          end

          class Number < Abstract
            def valid?(number)
              number.is_a?(Fixnum) || number.is_a?(Float)
            end
          end

          class ReturnValuesReuse < Abstract::Enum
            add :DontUse, :НеИспользовать
            add :DuringRequest, :НаВремяВызова
            add :DuringSession, :НаВремяСеанса
          end
        end

        def self.klass
          Classes
        end

        add :String, :Стока
        add :Boolean, :Булево
        add :Number, :Число
        add :ReturnValuesReuse, :ReturnValuesReuse
      end

      module MdCollections
        class MdCollection < RuEnNamed
          include IncludedInMdClass
          attr_accessor :md_class_name
          def initialize(en, ru, md_class_name, module_)
            super en, ru, module_
            self.md_class_name = md_class_name.to_sym
          end

          def md_class
            MdClasses.get(md_class_name)
          end
        end

        extend HaveContent

        def self.klass
          MdCollection
        end

        # Configuration Common
        add :CommonModules, :ОбщиеМодули, :CommonModule
        add :SessionParameters, :ПараметрыСеанса, :SessionParameter
        add :Roles, :Роли, :Role
        add :CommonAttributes, :ОбщиеРеквизиты, :CommonAttribute
        add :ExchangePlans, :ПланыОбмена, :ExchangePlan
        add :FilterCriteria, :КритерииОтбора, :FilterCriterion
        add :EventSubscriptions, :ПодпискиНаСобытия, :EventSubscription
        add :ScheduledJobs, :РегламентныеЗадания, :ScheduledJob
        add :FunctionalOptions, :ФункциональныеОпции,
          :FunctionalOption
        add :FunctionalOptionsParameters, :ПараметрыФункциональныхОпций,
          :FunctionalOptionsParameter
        add :DefinedTypes, :ОпределяемыеТипы, :DefinedType
        add :SettingsStorages, :ХранилищаНастроек, :SettingsStorage
        add :CommonForms, :ОбщиеФормы, :Form
        add :CommonCommands, :ОбщиеКоманды, :CommonCommand
        add :CommandGroups, :ГруппыКоманд, :CommandGroup
        add :CommonTemplates, :ОбщиеМакеты, :Template
        add :CommonPictures, :ОбщиеКартинки, :CommonPicture
        add :XDTOPackages, :ПакетыXDTO, :XDTOPackage
        add :HTTPServices, :HTTPСервисы, :HTTPService
        add :WebServices, :WebСервисы, :WebService
        add :WSReferences, :WSСсылки, :WSReference
        add :StyleItems, :ЭлементыСтиля, :StyleItem
        add :Interfaces, :Интерфейсы, :Interface
        add :Subsystems, :Подсистемы, :Subsystem
        add :Styles, :Стили, :Style
        add :Languages, :Языки, :Language

        # Configuration Main
        add :Constants, :Константы, :Constant
        add :Catalogs, :Справочники, :Catalog
        add :Documents, :Документы, :Document
        add :DocumentNumerators, :НумераторыДокументов, :DocumentNumerator
        add :Sequences, :Последовательности, :Sequence
        add :DocumentJournals, :ЖурналыДокументов, :DocumentJournal
        add :Enums, :Перечисления, :Enum
        add :Reports, :Отчеты, :Report
        add :DataProcessors, :Обработки, :DataProcessor
        add :ChartsOfCharacteristicTypes, :ПланыВидовХарактеристик,
          :ChartOfCharacteristicTypes
        add :ChartsOfAccounts, :ПланыСчетов, :ChartOfAccounts
        add :ChartsOfCalculationTypes, :ПланыВидовРасчета,
          :ChartOfCalculationTypes
        add :InformationRegisters, :РегистрыСведений, :InformationRegister
        add :AccumulationRegisters, :РегистрыНакопления, :AccumulationRegister
        add :AccountingRegisters, :РегистрыБухгалтерии, :AccountingRegister
        add :CalculationRegisters, :РегистрыРасчета, :CalculationRegister
        add :BusinessProcesses, :БизнесПроцессы, :BusinessProcess
        add :Tasks, :Задачи, :Task
        add :ExternalDataSources, :ВнешниеИсточникиДанных, :ExternalDataSource

        add :Forms, :Формы, :Form
        add :Attributes, :Реквизиты, :Attribute
        add :TabularSections, :ТабличныеЧасти, :TabularSection
        add :Templates, :Макеты, :Template
        add :Commands, :Команды, :Command

        add :Cubes, :Кубы, :Cube
        add :Tables, :Таблицы, :Table
        add :Functions, :Функции, :Function

        add :Columns, :Графы, :Graph

        add :AddressingAttributes, :РеквизитыАдресации, :AddressingAttribute

        add :DimensionTables, :ТаблицыИзмерений, :DimensionTable
        add :Dimensions, :Измерения, :Dimension
        add :Resources, :Ресурсы, :Resource

        add :URLTemplates, :ШаблоныURL, :HTTPServiceURLTemplate
        add :Methods, :Методы, :HttpServiceMethod

        add :Parameters, :Параметры, :WebServiceParameter
        add :EnumValues, :ЗначенияПеречисления, :EnumValue

        add :AccountingFlags, :ПризнакиУчета, :AccountingFlag
        add :ExtDimensionAccountingFlags, :ПризнакиУчетаСубконто,
          :ExtDimensionAccountingFlag
        add :Recalculations, :Перерасчеты, :Recalculation

        add :Fields, :Поля, :Field
        add :Operations, :Операции, :WebServiceOperation
      end

      module MdCollectionProperties
        class MdCollectionProperty < RuEnNamed
          include IncludedInMdClass
          def initialize(en, ru, module_)
            super en, ru, module_
          end

          def md_class
            MdClasses.get(md_class_name)
          end
        end

        extend HaveContent

        def self.klass
          MdCollectionProperty
        end

        add :DefaultRoles, :ОсновныеРоли
        add :AdditionalFullTextSearchDictionaries,
          :ДополнительныеСловариПолнотекстовогоПоиска
        # TODO: fill all 1C MetadataObjectPropertyValueCollection
      end

      module MdProperties
        COMMON_PREFIX = :Common
        class RawProp < RuEnNamed
          attr_accessor :type
          def initialize(en, ru, type, module_)
            super en, ru, module_
            self.type = type
          end
        end

        class Prop < RawProp
          include IncludedInMdClass
          attr_accessor :type, :owner
          def initialize(en, ru, type, owner, module_)
            super en, ru, find_type(type), module_
            self.owner = owner
          end

          def find_type(type)
            r = PropTypes.get(type)
            fail ArgumentError, "Type `#{type}'' not found" unless r
            r
          end
          private :find_type

          def const_name
            "#{module_}::#{cn}"
          end

          def cn
           "#{owner}_#{en}"
          end
        end

        extend HaveContent

        def self.klass
          Prop
        end

        def self.add(en, ru, type, owner = COMMON_PREFIX)
          r = klass.new(en, ru, type, owner, self)
          const_set r.cn, r
          content << r
          yield r if block_given?
        end

        def self.get(en_ru, md_class_en)
          get_for(en_ru, md_class_en) || get_for(en_ru, COMMON_PREFIX)
        end

        def self.get_for(en_ru, md_class_en)
          content_for(md_class_en)\
            .select {|r| r.en == en_ru.to_sym || r.ru == en_ru.to_sym}[0]
        end

        def self.content_for(owner)
          content.select {|p| p.owner == owner}
        end

        add :Name, :Имя, :String
        add :Comment, :Комментарий, :String
        add :Synonym, :Синоним, :String

        add :Copyright, :АвторскиеПрава, :String
        add :Version, :Версия, :String
        add :ConfigurationInformationAddress, :АдресИнформацииОКонфигурации,
          :String
        add :VendorInformationAddress, :АдресИнформацииОПоставщике, :String
        add :UpdateCatalogAddress, :АдресКаталогаОбновлений, :String
        add :BriefInformation, :КраткаяИнформация, :String
        add :DetailedInformation, :ПодробнаяИнформация, :String
        add :Vendor, :Поставщик, :String
        add :NamePrefix, :ПрефиксИмен, :String


        add :ExternalConnection, :ВнешнееСоединение, :Boolean
        add :ServerCall, :ВызовСервера, :Boolean
        add :Global, :Глобальный, :Boolean
        add :ClientOrdinaryApplication, :КлиентОбычноеПриложение, :Boolean
        add :ClientManagedApllication, :КлиентУправляемоеПриложение, :Boolean
        add :ReturnValuesReuse, :ПовторноеИспользованиеВозвращаемыхЗначений,
          :ReturnValuesReuse
        add :Privileged, :Привилегированный, :Boolean
        add :Server, :Сервер, :Boolean

        add :NumberLength, :ДлинаНомера, :Number
        add :CheckUnique, :КонтрольУникальности, :Boolean
        add :Explanation, :Пояснение, :String

        add :Autonumbering, :Автонумерация, :Boolean

        add :Tooltip, :Подсказка, :String
        add :ModifiesData, :ИзменяетДанные, :Boolean
        add :NameInDataSource, :ИмяВИсточникеДанных, :String

        add :ProcedureName, :ИмяПроцедуры, :String
        add :ExtendedPresentation, :РасширенноеПредставление, :String
        add :Namespace, :ПространствоИмен, :String
        add :ExtendedObjectPresentation, :РасширенноеПредставлениеОбъекта,
          :String
        add :CodeLength, :ДлинаКода, :Number
        add :Hierarchical, :Иерархический, :Boolean
        add :Event, :Событие, :String
        add :Handler, :Обработчик, :String

        add :Predefined, :Предопределенное, :Boolean, :ScheduledJob
        add :MethodName, :ИмяМетода, :String
        add :Use, :Использование, :Boolean, :ScheduledJob
        add :Key, :Ключ, :String

        add :LanguageCode, :КодЯзыка, :String
      end

      module MdClasses
        COLLECTIONS_A_T_F_C_T = %w{Attributes
        TabularSections
        Forms
        Commands
        Templates}

        def self.get_by_full_name(full_name)
          split = full_name.split('.')
          get(split[split.size - 2])
        end

        module DevHelper
          def snippet_add_property
            undefined_properties.map do |en|
              prop = raw_props.select {|p| p.en == en}[0]
              "add :#{prop.en}, :#{prop.ru}, :FIXME_TYPE"
            end
          end

          def snippet_add_collection
            undefined_properties.map do |en|
              prop = raw_props.select {|p| p.en == en}[0]
              "add :#{prop.en}, :#{prop.ru}, :FIXME_MD_CLASS"
            end
          end
        end
        extend HaveContent

        def self.klass
          MdClass
        end

        class MdClass < RuEnNamed
          include DevHelper
          DEF_PROPS = %w{Name Synonym Comment}

          def initialize(en, ru, module_)
            super en, ru, module_
            yield self if block_given?
          end

          def rights=(arr)
            @rights = add_array arr, Rights
          end

          def rights
            @rights ||= []
          end

          def properties=(arr)
            @properties = find_properties(arr + DEF_PROPS)
          end

          def find_properties(arr)
            arr.map do |word|
              fail ArgumentError, "#{word} not found in #{MdProperties}" unless\
                MdProperties.get(word, en)
              MdProperties.get(word, en)
            end
          end

          def properties
            @properties ||= add_array DEF_PROPS, MdProperties
          end

          def collection_properties=(arr)
            @collection_properties = find_collection_properties(arr)
          end

          def find_collection_properties(arr)
            arr.map do |word|
              fail ArgumentError,
                "#{word} not found in #{MdCollectionProperties}" unless\
                MdCollectionProperties.get(word)
              MdCollectionProperties.get(word)
            end
          end

          def collection_properties
            @collection_properties ||= []
          end

          def add_array(arr, module_)
            arr.map do |word|
              fail ArgumentError, "#{word} not found in #{module_}" unless\
                module_.get(word)
              module_.get(word)
            end
          end
          private :add_array

          def modules=(arr)
            @modules = add_array arr, Modules
          end

          def modules
            @modules ||= []
          end

          def collections=(arr)
            @collections = add_array arr, MdCollections
          end

          def collections
            @collections ||= []
          end

          def all_included
            rights + collections + modules + properties
          end

          # Raw properties descriptions like 1C syntax help:
          # +HTTPСервисы (HTTPServices)+ First word is Ru syntax
          # second word is En syntax.
          # You can pass the third word. The third word is interpreted as a type
          def raw_props=(s)
            s.each_line do |l|
              l.strip.gsub(/\(|\)/,' ') =~
                %r{(?<ru>\S+)\s+(?<en>\S+)(\s+(?<type>\S+))?}
              next unless Regexp.last_match
              lm = Regexp.last_match
              add_raw_prop(lm[:ru], lm[:en], lm[:type])
            end
          end

          def add_raw_prop(ru, en, type)
            fail ArgumentError,
              "Invalid En syntax: `#{en}'" if en =~ %r{[а-яА-Я]}
            raw_props << MdProperties::RawProp.new(en, ru, type, self.class)
          end
          private :add_raw_prop

          def raw_props
            @raw_props ||= []
          end

          def undefined_properties
            raw_props.map {|p| p.en} - defined_properties
          end

          def defined_properties
            (modules + collections + properties).map {|p| p.en}
          end
        end

        add :Configuration, :Конфигурация do |klass|
          klass.rights = %w{Администрирование
                            АдминистрированиеДанных
                            ОбновлениеКонфигурацииБазыДанных
                            МонопольныйРежим
                            АктивныеПользователи
                            ЖурналРегистрации
                            ТонкийКлиент
                            ВебКлиент
                            ТолстыйКлиент
                            ВнешнееСоединение
                            Automation
                            РежимВсеФункции
                            СохранениеДанныхПользователя
                            АдминистрированиеРасширенийКонфигурации
                            ИнтерактивноеОткрытиеВнешнихОбработок
                            ИнтерактивноеОткрытиеВнешнихОтчетов
                            Вывод
          }

          klass.modules = %w{ExternalConnectionModule
                             OrdinaryApplicationModule
                             SessionModule
                             ManagedApplicationModule
          }

          klass.collections = %w{HTTPServices
                                Languages
                                CommonModules
                                SessionParameters
                                Roles
                                CommonAttributes
                                ExchangePlans
                                FilterCriteria
                                EventSubscriptions
                                ScheduledJobs
                                FunctionalOptions
                                FunctionalOptionsParameters
                                DefinedTypes
                                SettingsStorages
                                CommonForms
                                CommonCommands
                                CommandGroups
                                CommonTemplates
                                CommonPictures
                                XDTOPackages
                                WebServices
                                WSReferences
                                StyleItems
                                Constants
                                Catalogs
                                Documents
                                DocumentNumerators
                                Sequences
                                DocumentJournals
                                Enums
                                Reports
                                DataProcessors
                                ChartsOfCharacteristicTypes
                                ChartsOfAccounts
                                ChartsOfCalculationTypes
                                InformationRegisters
                                AccumulationRegisters
                                AccountingRegisters
                                CalculationRegisters
                                BusinessProcesses
                                Tasks
                                Interfaces
                                ExternalDataSources
                                Subsystems
                                Styles
          }

          klass.properties = %w{Copyright
                               Version
                               ConfigurationInformationAddress
                               VendorInformationAddress
                               UpdateCatalogAddress
                               BriefInformation
                               DetailedInformation
                               Vendor
                               NamePrefix
          }

          klass.collection_properties = %w{
            AdditionalFullTextSearchDictionaries
            DefaultRoles
          }

          klass.raw_props = %{
            HTTPСервисы (HTTPServices)
            WebСервисы (WebServices)
            WSСсылки (WSReferences)
            АвторскиеПрава (Copyright)
            АдресИнформацииОКонфигурации (ConfigurationInformationAddress)
            АдресИнформацииОПоставщике (VendorInformationAddress)
            АдресКаталогаОбновлений (UpdateCatalogAddress)
            БизнесПроцессы (BusinessProcesses)
            ВариантВстроенногоЯзыка (ScriptVariant)
            Версия (Version)
            ВключатьСправкуВСодержание (IncludeHelpInContents)
            ВнешниеИсточникиДанных (ExternalDataSources)
            ГруппыКоманд (CommandGroups)
            Документы (Documents)
            ДополнительнаяФормаКонстант (AuxiliaryConstantsForm)
            ДополнительныеСловариПолнотекстовогоПоиска (AdditionalFullTextSearchDictionaries)
            ЖурналыДокументов (DocumentJournals)
            Задачи (Tasks)
            Заставка (Splash)
            ИнтерфейсКлиентскогоПриложения (ClientApplicationInterface)
            Интерфейсы (Interfaces)
            ИспользоватьОбычныеФормыВУправляемомПриложении (UseOrdinaryFormInManagedApplication)
            ИспользоватьУправляемыеФормыВОбычномПриложении (UseManagedFormInOrdinaryApplication)
            КартинкаОсновногоРаздела (MainSectionPicture)
            КомандныйИнтерфейс (CommandInterface)
            КомандныйИнтерфейсОсновногоРаздела (MainSectionCommandInterface)
            Константы (Constants)
            КраткаяИнформация (BriefInformation)
            КритерииОтбора (FilterCriteria)
            Логотип (Logo)
            МодульВнешнегоСоединения (ExternalConnectionModule)
            МодульОбычногоПриложения (OrdinaryApplicationModule)
            МодульСеанса (SessionModule)
            МодульУправляемогоПриложения (ManagedApplicationModule)
            НазначенияИспользования (UsePurposes)
            НумераторыДокументов (DocumentNumerators)
            Обработки (DataProcessors)
            ОбщиеКартинки (CommonPictures)
            ОбщиеКоманды (CommonCommands)
            ОбщиеМакеты (CommonTemplates)
            ОбщиеМодули (CommonModules)
            ОбщиеРеквизиты (CommonAttributes)
            ОбщиеФормы (CommonForms)
            ОпределяемыеТипы (DefinedTypes)
            ОсновнаяФормаВариантаОтчета (DefaultReportVariantForm)
            ОсновнаяФормаКонстант (DefaultConstantsForm)
            ОсновнаяФормаНастроекДинамическогоСписка (DefaultDynamicListSettingsForm)
            ОсновнаяФормаНастроекОтчета (DefaultReportSettingsForm)
            ОсновнаяФормаОтчета (DefaultReportForm)
            ОсновнаяФормаПоиска (DefaultSearchForm)
            ОсновнойИнтерфейс (DefaultInterface)
            ОсновнойРежимЗапуска (DefaultRunMode)
            ОсновнойСтиль (DefaultStyle)
            ОсновнойЯзык (DefaultLanguage)
            ОсновныеРоли (DefaultRoles)
            Отчеты (Reports)
            ПакетыXDTO (XDTOPackages)
            ПараметрыСеанса (SessionParameters)
            ПараметрыФункциональныхОпций (FunctionalOptionsParameters)
            Перечисления (Enums)
            ПланыВидовРасчета (ChartsOfCalculationTypes)
            ПланыВидовХарактеристик (ChartsOfCharacteristicTypes)
            ПланыОбмена (ExchangePlans)
            ПланыСчетов (ChartsOfAccounts)
            ПодпискиНаСобытия (EventSubscriptions)
            ПодробнаяИнформация (DetailedInformation)
            Подсистемы (Subsystems)
            Последовательности (Sequences)
            Поставщик (Vendor)
            ПрефиксИмен (NamePrefix)
            РабочаяОбластьНачальнойСтраницы (HomePageWorkArea)
            РегистрыБухгалтерии (AccountingRegisters)
            РегистрыНакопления (AccumulationRegisters)
            РегистрыРасчета (CalculationRegisters)
            РегистрыСведений (InformationRegisters)
            РегламентныеЗадания (ScheduledJobs)
            РежимАвтонумерацииОбъектов (ObjectAutonumerationMode)
            РежимИспользованияМодальности (ModalityUseMode)
            РежимИспользованияСинхронныхВызововРасширенийПлатформыИВнешнихКомпонент (SynchronousPlatformExtensionAndAddInCallUseMode)
            РежимСовместимости (CompatibilityMode)
            РежимСовместимостиИнтерфейса (InterfaceCompatibilityMode)
            РежимСовместимостиРасширенияКонфигурации (ConfigurationExtensionCompatibilityMode)
            РежимУправленияБлокировкойДанных (DataLockControlMode)
            РодительскиеКонфигурации (ParentConfigurations)
            Роли (Roles)
            СвойстваОбъектов (ObjectProperties)
            Справка (Help)
            Справочники (Catalogs)
            Стили (Styles)
            ТребуемыеРазрешенияМобильногоПриложения (RequiredMobileApplicationPermissions)
            ФрагментКомандногоИнтерфейса (CommandInterfaceFragment)
            ФункциональныеОпции (FunctionalOptions)
            ХранилищаНастроек (SettingsStorages)
            ХранилищеВариантовОтчетов (ReportsVariantsStorage)
            ХранилищеНастроекДанныхФорм (FormDataSettingsStorage)
            ХранилищеОбщихНастроек (CommonSettingsStorage)
            ХранилищеПользовательскихНастроекДинамическихСписков (DynamicListsUserSettingsStorage)
            ХранилищеПользовательскихНастроекОтчетов (ReportsUserSettingsStorage)
            ЭлементыСтиля (StyleItems)
            Языки (Languages)
          }
        end

        add :CommonModule, :ОбщийМодуль do |klass|
          klass.modules = %w{Module}

          klass.properties = %w{ExternalConnection
                              ServerCall
                              Global
                              ClientOrdinaryApplication
                              ClientManagedApllication
                              ReturnValuesReuse
                              Privileged
                              Server
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            ВнешнееСоединение (ExternalConnection)
            ВызовСервера (ServerCall)
            Глобальный (Global)
            КлиентОбычноеПриложение (ClientOrdinaryApplication)
            КлиентУправляемоеПриложение (ClientManagedApllication)
            Модуль (Module)
            ПовторноеИспользованиеВозвращаемыхЗначений (ReturnValuesReuse)
            Привилегированный (Privileged)
            Сервер (Server)
          }
        end

        add :BusinessProcess, :БизнесПроцесс do |klass|
          klass.rights = %w{
                    Чтение
                    Добавление
                    Изменение
                    Удаление
                    Просмотр
                    ИнтерактивноеДобавление
                    Редактирование
                    ИнтерактивноеУдаление
                    ИнтерактивнаяПометкаУдаления
                    ИнтерактивноеСнятиеПометкиУдаления
                    ИнтерактивноеУдалениеПомеченных
                    ВводПоСтроке
                    ИнтерактивнаяАктивация
                    Старт
                    ИнтерактивныйСтарт
            }

          klass.modules = %w{ManagerModule ObjectModule}

          klass.collections = %w{
                  TabularSections
                  Forms
                  Templates
                  Commands
                  Attributes
          }

          klass.properties = %w{
                  NumberLength
                  CheckUnique
                  Explanation
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            СтандартныеРеквизиты (StandardAttributes)
            Автонумерация (Autonumbering)
            ВводитсяНаОсновании (BasedOn)
            ВводПоСтроке (InputByString)
            ВключатьСправкуВСодержание (IncludeHelpInContents)
            ДлинаНомера (NumberLength)
            ДополнительнаяФормаДляВыбора (AuxiliaryChoiceForm)
            ДополнительнаяФормаОбъекта (AuxiliaryObjectForm)
            ДополнительнаяФормаСписка (AuxiliaryListForm)
            ДопустимаяДлинаНомера (NumberAllowedLength)
            Задача (Task)
            ИспользоватьСтандартныеКоманды (UseStandardCommands)
            ИсторияВыбораПриВводе (ChoiceHistoryOnInput)
            КартаМаршрута (Flowchart)
            Команды (Commands)
            КонтрольУникальности (CheckUnique)
            Макеты (Templates)
            МодульМенеджера (ManagerModule)
            МодульОбъекта (ObjectModule)
            ОсновнаяФормаДляВыбора (DefaultChoiceForm)
            ОсновнаяФормаОбъекта (DefaultObjectForm)
            ОсновнаяФормаСписка (DefaultListForm)
            ПериодичностьНомера (NumberPeriodicity)
            ПолнотекстовыйПоиск (FullTextSearch)
            ПолнотекстовыйПоискПриВводеПоСтроке (FullTextSearchOnInputByString)
            ПоляБлокировкиДанных (DataLockFields)
            Пояснение (Explanation)
            ПредставлениеОбъекта (ObjectPresentation)
            ПредставлениеСписка (ListPresentation)
            ПривилегированныйРежимПриСозданииЗадач (TaskCreatingPrivilegedMode)
            РасширенноеПредставлениеОбъекта (ExtendedObjectPresentation)
            РасширенноеПредставлениеСписка (ExtendedListPresentation)
            РежимПолученияДанныхВыбораПриВводеПоСтроке (ChoiceDataGetModeOnInputByString)
            РежимУправленияБлокировкойДанных (DataLockControlMode)
            Реквизиты (Attributes)
            СозданиеПриВводе (CreateOnInput)
            СпособПоискаСтрокиПриВводеПоСтроке (SearchStringModeOnInputByString)
            СпособРедактирования (EditType)
            Справка (Help)
            ТабличныеЧасти (TabularSections)
            ТипНомера (NumberType)
            Формы (Forms)
            Характеристики (Characteristics)
          }
        end

        add :ExternalDataSource, :ВнешнийИсточникДанных do |klass|
          klass.rights = %w{
            Использование
            Администрирование
            ИзменениеСтандартнойАутентификации
            ИзменениеСтандартнойАутентификацииСеанса
            ИзменениеАутентификацииОССеанса
          }

          klass.collections = %w{
           Cubes
           Tables
           Functions
          }

          klass.properties = %w{
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            Кубы (Cubes)
            РежимУправленияБлокировкойДанных (DataLockControlMode)
            Таблицы (Tables)
            Функции (Functions)
          }
        end

        add :Graph, :Графа do |klass|
          klass.properties = %w{
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            Индексирование (Indexing)
            Ссылки (References)
          }
        end

        add :CommandGroup, :ГруппаКоманд do |klass|
          klass.properties = %w{
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            Картинка (Picture)
            Категория (Category)
            Отображение (Representation)
            Подсказка (Tooltip)
          }
        end

        add :Document, :Документ do |klass|
          klass.rights = %w{
            Чтение
            Добавление
            Изменение
            Удаление
            Проведение
            ОтменаПроведения
            Просмотр
            ИнтерактивноеДобавление
            Редактирование
            ИнтерактивноеУдаление
            ИнтерактивнаяПометкаУдаления
            ИнтерактивноеСнятиеПометкиУдаления
            ИнтерактивноеУдалениеПомеченных
            ИнтерактивноеПроведение
            ИнтерактивноеПроведениеНеОперативное
            ИнтерактивнаяОтменаПроведения
            ИнтерактивноеИзменениеПроведенных
            ВводПоСтроке
          }

          klass.modules = %w{
            ManagerModule
            ObjectModule
          }

          klass.collections = COLLECTIONS_A_T_F_C_T

          klass.properties = %w{
            Autonumbering
            NumberLength
            CheckUnique
            Explanation
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            СтандартныеРеквизиты (StandardAttributes)
            Автонумерация (Autonumbering)
            ВводитсяНаОсновании (BasedOn)
            ВводПоСтроке (InputByString)
            ВключатьСправкуВСодержание (IncludeHelpInContents)
            Движения (RegisterRecords)
            ДлинаНомера (NumberLength)
            ДополнительнаяФормаДляВыбора (AuxiliaryChoiceForm)
            ДополнительнаяФормаОбъекта (AuxiliaryObjectForm)
            ДополнительнаяФормаСписка (AuxiliaryListForm)
            ДопустимаяДлинаНомера (NumberAllowedLength)
            ЗаписьДвиженийПриПроведении (ActionsWritingOnPost)
            ЗаполнениеПоследовательностей (SequenceFilling)
            ИспользоватьСтандартныеКоманды (UseStandardCommands)
            ИсторияВыбораПриВводе (ChoiceHistoryOnInput)
            Команды (Commands)
            КонтрольУникальности (CheckUnique)
            Макеты (Templates)
            МодульМенеджера (ManagerModule)
            МодульОбъекта (ObjectModule)
            Нумератор (Numerator)
            ОперативноеПроведение (RealTimePosting)
            ОсновнаяФормаДляВыбора (DefaultChoiceForm)
            ОсновнаяФормаОбъекта (DefaultObjectForm)
            ОсновнаяФормаСписка (DefaultListForm)
            ПериодичностьНомера (NumberPeriodicity)
            ПолнотекстовыйПоиск (FullTextSearch)
            ПолнотекстовыйПоискПриВводеПоСтроке (FullTextSearchOnInputByString)
            ПоляБлокировкиДанных (DataLockFields)
            Пояснение (Explanation)
            ПредставлениеОбъекта (ObjectPresentation)
            ПредставлениеСписка (ListPresentation)
            ПривилегированныйРежимПриОтменеПроведения (PrivilegedUnpostingMode)
            ПривилегированныйРежимПриПроведении (PrivilegedPostingMode)
            Проведение (Posting)
            РасширенноеПредставлениеОбъекта (ExtendedObjectPresentation)
            РасширенноеПредставлениеСписка (ExtendedListPresentation)
            РежимПолученияДанныхВыбораПриВводеПоСтроке (ChoiceDataGetModeOnInputByString)
            РежимУправленияБлокировкойДанных (DataLockControlMode)
            Реквизиты (Attributes)
            СозданиеПриВводе (CreateOnInput)
            СпособПоискаСтрокиПриВводеПоСтроке (SearchStringModeOnInputByString)
            Справка (Help)
            ТабличныеЧасти (TabularSections)
            ТипНомера (NumberType)
            УдалениеДвижений (RegisterRecordsDeletion)
            Формы (Forms)
            Характеристики (Characteristics)
          }
        end

        add :DocumentJournal, :ЖурналДокументов do |klass|
          klass.rights = %w{
            Чтение
            Просмотр
          }

          klass.modules = %w{
            ManagerModule
          }

          klass.collections = %w{
            Columns
            Forms
            Commands
            Templates
          }

          klass.properties = %w{
            Explanation
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            СтандартныеРеквизиты (StandardAttributes)
            ВключатьСправкуВСодержание (IncludeHelpInContents)
            Графы (Columns)
            ДополнительнаяФорма (AuxiliaryForm)
            ИспользоватьСтандартныеКоманды (UseStandardCommands)
            Команды (Commands)
            Макеты (Templates)
            МодульМенеджера (ManagerModule)
            ОсновнаяФорма (DefaultForm)
            Пояснение (Explanation)
            ПредставлениеСписка (ListPresentation)
            РасширенноеПредставлениеСписка (ExtendedListPresentation)
            РегистрируемыеДокументы (RegisteredDocuments)
            Справка (Help)
            Формы (Forms)
          }
        end

        add :Task, :Задача do |klass|
          klass.rights = %w{
            Чтение
            Добавление
            Изменение
            Удаление
            Просмотр
            ИнтерактивноеДобавление
            Редактирование
            ИнтерактивноеУдаление
            ИнтерактивнаяПометкаУдаления
            ИнтерактивноеСнятиеПометкиУдаления
            ИнтерактивноеУдалениеПомеченных
            ВводПоСтроке
            ИнтерактивнаяАктивация
            Выполнение
            ИнтерактивноеВыполнение
          }

          klass.modules = %w{
            ManagerModule
            ObjectModule
          }

          klass.collections =  COLLECTIONS_A_T_F_C_T +
            %w{AddressingAttributes}

          klass.properties = %w{
            CheckUnique
            NumberLength
            Autonumbering
            Explanation
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            СтандартныеРеквизиты (StandardAttributes)
            Автонумерация (Autonumbering)
            АвтоПрефиксНомераЗадачи (TaskNumberAutoPrefix)
            Адресация (Addressing)
            ВводитсяНаОсновании (BasedOn)
            ВводПоСтроке (InputByString)
            ВключатьСправкуВСодержание (IncludeHelpInContents)
            ДлинаНаименования (DescriptionLength)
            ДлинаНомера (NumberLength)
            ДополнительнаяФормаДляВыбора (AuxiliaryChoiceForm)
            ДополнительнаяФормаОбъекта (AuxiliaryObjectForm)
            ДополнительнаяФормаСписка (AuxiliaryListForm)
            ДопустимаяДлинаНомера (NumberAllowedLength)
            ИспользоватьСтандартныеКоманды (UseStandardCommands)
            ИсторияВыбораПриВводе (ChoiceHistoryOnInput)
            Команды (Commands)
            КонтрольУникальности (CheckUnique)
            Макеты (Templates)
            МодульМенеджера (ManagerModule)
            МодульОбъекта (ObjectModule)
            ОсновнаяФормаДляВыбора (DefaultChoiceForm)
            ОсновнаяФормаОбъекта (DefaultObjectForm)
            ОсновнаяФормаСписка (DefaultListForm)
            ОсновноеПредставление (DefaultPresentation)
            ОсновнойРеквизитАдресации (MainAddressingAttribute)
            ПолнотекстовыйПоиск (FullTextSearch)
            ПолнотекстовыйПоискПриВводеПоСтроке (FullTextSearchOnInputByString)
            ПоляБлокировкиДанных (DataLockFields)
            Пояснение (Explanation)
            ПредставлениеОбъекта (ObjectPresentation)
            ПредставлениеСписка (ListPresentation)
            РасширенноеПредставлениеОбъекта (ExtendedObjectPresentation)
            РасширенноеПредставлениеСписка (ExtendedListPresentation)
            РежимПолученияДанныхВыбораПриВводеПоСтроке (ChoiceDataGetModeOnInputByString)
            РежимУправленияБлокировкойДанных (DataLockControlMode)
            Реквизиты (Attributes)
            РеквизитыАдресации (AddressingAttributes)
            СозданиеПриВводе (CreateOnInput)
            СпособПоискаСтрокиПриВводеПоСтроке (SearchStringModeOnInputByString)
            СпособРедактирования (EditType)
            Справка (Help)
            ТабличныеЧасти (TabularSections)
            ТекущийИсполнитель (CurrentPerformer)
            ТипНомера (NumberType)
            Формы (Forms)
            Характеристики (Characteristics)
          }
        end

        add :EnumValue, :ЗначениеПеречисления do |klass|
          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
          }
        end

        add :Dimension, :Измерение do |klass|
          klass.rights = %w{
            Просмотр
            Редактирование
          }

          klass.properties = %w{
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            БазовоеИзмерение (BaseDimension)
            Балансовый (Balance)
            БыстрыйВыбор (QuickChoice)
            Ведущее (Master)
            ВыборГруппИЭлементов (ChoiceFoldersAndItems)
            ВыделятьОтрицательные (MarkNegatives)
            ДанныеВедущихРегистров (LeadingRegisterData)
            ЗаполнятьИзДанныхЗаполнения (FillFromFillingValue)
            ЗапрещатьНезаполненныеЗначения (DenyIncompleteValues)
            ИзмерениеРегистра (RegisterDimension)
            Индексирование (Indexing)
            ИспользованиеВИтогах (UseInTotals)
            ИсторияВыбораПриВводе (ChoiceHistoryOnInput)
            Маска (Mask)
            МногострочныйРежим (MultiLine)
            ОсновнойОтбор (MainFilter)
            ПараметрыВыбора (ChoiceParameters)
            Подсказка (Tooltip)
            ПолнотекстовыйПоиск (FullTextSearch)
            ПризнакУчета (AccountingFlag)
            ПроверкаЗаполнения (FillChecking)
            РасширенноеРедактирование (ExtendedEdit)
            РежимПароля (PasswordMode)
            СвязиПараметровВыбора (ChoiceParameterLinks)
            СвязьПоТипу (LinkByType)
            СозданиеПриВводе (CreateOnInput)
            СоответствиеДвижениям (RegisterRecordsMap)
            СоответствиеДокументам (DocumentMap)
            Тип (Type)
            ФормаВыбора (ChoiceForm)
            Формат (Format)
            ФорматРедактирования (EditFormat)
          }
        end

        add :Interface, :Интерфейс do |klass|
          klass.rights = %w{
            Использование
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            Интерфейс (Interface)
            Переключаемый (Switchable)
          }
        end

        add :Command, :Команда do |klass|
          klass.rights = %w{
            Просмотр
          }

          klass.modules = %w{
            CommandModule
          }

          klass.properties = %w{
            Tooltip
            ModifiesData
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            ВключатьСправкуВСодержание (IncludeHelpInContents)
            Группа (Group)
            ИзменяетДанные (ModifiesData)
            Картинка (Picture)
            МодульКоманды (CommandModule)
            Отображение (Representation)
            Подсказка (Tooltip)
            РежимИспользованияПараметра (ParameterUsageMode)
            СочетаниеКлавиш (Shortcut)
            ТипПараметраКоманды (CommandParameterType)
          }

        end

        add :Constant, :Константа do |klass|
          klass.rights = %w{
            Чтение
            Изменение
            Просмотр
            Редактирование
          }

          klass.modules = %w{
            ValueManagerModule
          }

          klass.properties = %w{
            Explanation
            ExtendedPresentation
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            БыстрыйВыбор (QuickChoice)
            ВыборГруппИЭлементов (ChoiceFoldersAndItems)
            ВыделятьОтрицательные (MarkNegatives)
            ИспользоватьСтандартныеКоманды (UseStandardCommands)
            Маска (Mask)
            МногострочныйРежим (MultiLine)
            МодульМенеджераЗначения (ValueManagerModule)
            ПараметрыВыбора (ChoiceParameters)
            Подсказка (Tooltip)
            Пояснение (Explanation)
            ПроверкаЗаполнения (FillChecking)
            РасширенноеПредставление (ExtendedPresentation)
            РасширенноеРедактирование (ExtendedEdit)
            РежимПароля (PasswordMode)
            РежимУправленияБлокировкойДанных (DataLockControlMode)
            СвязиПараметровВыбора (ChoiceParameterLinks)
            СвязьПоТипу (LinkByType)
            Тип (Type)
            ФормаВыбора (ChoiceForm)
            Формат (Format)
            ФорматРедактирования (EditFormat)
          }
        end

        add :FilterCriterion, :КритерийОтбора do |klass|
          klass.rights = %w{
            Просмотр
          }

          klass.modules = %w{
            ManagerModule
          }

          klass.collections = %w{
            Forms
            Commands
          }

          klass.properties = %w{
            Explanation
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            ДополнительнаяФорма (AuxiliaryForm)
            ИспользоватьСтандартныеКоманды (UseStandardCommands)
            Команды (Commands)
            МодульМенеджера (ManagerModule)
            ОсновнаяФорма (DefaultForm)
            Пояснение (Explanation)
            ПредставлениеСписка (ListPresentation)
            РасширенноеПредставлениеСписка (ExtendedListPresentation)
            Состав (Content)
            СтандартныеРеквизиты (StandardProperties)
            Тип (Type)
            Формы (Forms)
          }
        end

        add :Cube, :Куб do |klass|
          klass.rights = %w{
            Чтение
            Просмотр
          }

          klass.modules = %w{
            ManagerModule
            RecordSetModule
          }

          klass.collections = %w{
            DimensionTables
            Dimensions
            Resources
            Forms
            Commands
            Templates
          }

          klass.properties = %w{
            NameInDataSource
            Explanation
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            ВключатьСправкуВСодержание (IncludeHelpInContents)
            Измерения (Dimensions)
            ИмяВИсточникеДанных (NameInDataSource)
            ИспользоватьСтандартныеКоманды (UseStandardCommands)
            Макеты (Templates)
            МодульМенеджера (ManagerModule)
            МодульНабораЗаписей (RecordSetModule)
            ОсновнаяФормаЗаписи (DefaultRecordForm)
            ОсновнаяФормаСписка (DefaultListForm)
            Пояснение (Explanation)
            ПредставлениеЗаписи (RecordPresentation)
            ПредставлениеСписка (ListPresentation)
            РасширенноеПредставлениеЗаписи (ExtendedRecordPresentation)
            РасширенноеПредставлениеСписка (ExtendedListPresentation)
            Ресурсы (Resources)
            Справка (Help)
            ТаблицыИзмерений (DimensionTables)
            Формы (Forms)
            Команды (Commands)
            Макеты (Templates)
         }
        end

        add :Template, :Макет do |klass|
          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            Макет (Template)
            ТипМакета (TemplateType)
          }
        end

        add :DocumentNumerator, :Нумератор do |klass|
          klass.properties = %w{
            NumberLength
            CheckUnique
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            ДлинаНомера (NumberLength)
            ДопустимаяДлинаНомера (NumberAllowedLength)
            КонтрольУникальности (CheckUnique)
            ПериодичностьНомера (NumberPeriodicity)
            ТипНомера (NumberType)
          }
        end

        add :DataProcessor, :Обработка do |klass|
          klass.rights = %w{
            Использование
            Просмотр
          }

          klass.modules = %w{
            ManagerModule
            ObjectModule
          }

          klass.collections = COLLECTIONS_A_T_F_C_T

          klass.properties = %w{
            Explanation
            ExtendedPresentation
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            ВключатьСправкуВСодержание (IncludeHelpInContents)
            ДополнительнаяФорма (AuxiliaryForm)
            ИспользоватьСтандартныеКоманды (UseStandardCommands)
            Команды (Commands)
            Макеты (Templates)
            МодульМенеджера (ManagerModule)
            МодульОбъекта (ObjectModule)
            ОсновнаяФорма (DefaultForm)
            Пояснение (Explanation)
            РасширенноеПредставление (ExtendedPresentation)
            Реквизиты (Attributes)
            Справка (Help)
            СтандартныеРеквизиты (StandardProperties)
            ТабличныеЧасти (TabularSections)
            Формы (Forms)
          }
        end

        add :CommonPicture, :ОбщаяКартинка do |klass|
          klass.properties = %w{
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            Картинка (Picture)
          }
        end

        add :CommonCommand, :ОбщаяКоманда do |klass|
          klass.rights = %w{
            Просмотр
          }

          klass.modules = %w{
            CommandModule
          }

          klass.properties = %w{
            ModifiesData
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            ВключатьСправкуВСодержание (IncludeHelpInContents)
            Группа (Group)
            ИзменяетДанные (ModifiesData)
            Картинка (Picture)
            МодульКоманды (CommandModule)
            Отображение (Representation)
            Подсказка (ToolTip)
            РежимИспользованияПараметра (ParameterUsageMode)
            СочетаниеКлавиш (Shortcut)
            ТипПараметраКоманды (CommandParameterType)
          }
        end

        add :CommonAttribute, :ОбщийРеквизит do |klass|
          klass.rights = %w{
            Просмотр
            Редактирование
          }

          klass.properties = %w{
            Tooltip
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            АвтоИспользование (AutoUse)
            БыстрыйВыбор (QuickChoice)
            ВыделятьОтрицательные (MarkNegatives)
            ЗаполнятьИзДанныхЗаполнения (FillFromFillingValue)
            ЗначениеЗаполнения (FillingValue)
            ЗначениеРазделенияДанных (DataSeparationValue)
            Индексирование (Indexing)
            ИспользованиеРазделенияДанных (DataSeparationUse)
            ИспользованиеРазделяемыхДанных (SeparatedDataUse)
            ИсторияВыбораПриВводе (ChoiceHistoryOnInput)
            Маска (Mask)
            МногострочныйРежим (MultiLine)
            Подсказка (Tooltip)
            ПолнотекстовыйПоиск (FullTextSearch)
            ПроверкаЗаполнения (FillChecking)
            РазделениеАутентификации (AuthenticationSeparation)
            РазделениеДанных (DataSeparation)
            РазделениеПользователей (UsersSeparation)
            РасширенноеРедактирование (ExtendedEdit)
            РежимПароля (PasswordMode)
            СозданиеПриВводе (CreateOnInput)
            Состав (Content)
            Тип (Type)
            УсловноеРазделение (ConditionalSeparation)
            ФормаВыбора (ChoiceForm)
            Формат (Format)
            ФорматРедактирования (EditFormat)
          }
        end

        add :HTTPServiceURLTemplate, :ШаблонURLHTTPСервиса do |klass|
          klass.collections = %w{
            Methods
          }

          klass.properties = %w{
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            Методы (Methods)
            Шаблон (Template)
          }
        end

        add :WebServiceOperation, :ОперацияWebСервиса do |klass|
          klass.rights = %w{
            Использование
          }

          klass.collections = %w{
            Parameters
          }

          klass.properties = %w{
            ProcedureName
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            ВозможноПустое (Nillable)
            ВТранзакции (Transactioned)
            ИмяПроцедуры (ProcedureName)
            Параметры (Parameters)
            РежимУправленияБлокировкойДанных (DataLockControlMode)
            ТипВозвращаемогоЗначенияXDTO (XDTOReturningValueType)
          }
        end

        add :DefinedType, :ОпределяемыйТип do |klass|
          klass.properties = %w{
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            Тип (Type)
          }
        end

        add :Report, :Отчет do |klass|
          klass.rights = %w{
            Использование
            Просмотр
          }

          klass.modules = %w{
            ManagerModule
            ObjectModule
          }

          klass.collections = COLLECTIONS_A_T_F_C_T

          klass.properties = %w{
            Explanation
            ExtendedPresentation
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            ВключатьСправкуВСодержание (IncludeHelpInContents)
            ДополнительнаяФорма (AuxiliaryForm)
            ДополнительнаяФормаНастроек (AuxiliarySettingsForm)
            ИспользоватьСтандартныеКоманды (UseStandardCommands)
            Команды (Commands)
            Макеты (Templates)
            МодульМенеджера (ManagerModule)
            МодульОбъекта (ObjectModule)
            ОсновнаяСхемаКомпоновкиДанных (MainDataCompositionSchema)
            ОсновнаяФорма (DefaultForm)
            ОсновнаяФормаВарианта (DefaultVariantForm)
            ОсновнаяФормаНастроек (DefaultSettingsForm)
            Пояснение (Explanation)
            РасширенноеПредставление (ExtendedPresentation)
            Реквизиты (Attributes)
            Справка (Help)
            СтандартныеРеквизиты (StandardProperties)
            ТабличныеЧасти (TabularSections)
            Формы (Forms)
            ХранилищеВариантов (VariantsStorage)
            ХранилищеНастроек (SettingsStorage)
          }
        end

        add :XDTOPackage, :ПакетXDTO do |klass|
          klass.properties = %w{
            Namespace
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            Пакет (Package)
            ПространствоИмен (Namespace)
          }
        end

        add :SessionParameter, :ПараметрСеанса do |klass|
          klass.rights = %w{
            Получение
            Установка
          }

          klass.properties = %w{
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            Тип (Type)
          }
        end

        add :FunctionalOptionsParameter, :ПараметрФункциональныхОпций do |klass|
          klass.properties = %w{
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            Использование (Use)
          }
        end

        add :WebServiceParameter, :ПараметрWebСервиса do |klass|
          klass.properties = %w{
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            ВозможноПустое (Nillable)
            НаправлениеПередачи (TransferDirection)
            ТипЗначенияXDTO (XDTOValueType)
          }
        end

        add :Recalculation, :Перерасчет do |klass|
          klass.rights = %w{
            Чтение
            Изменение
          }

          klass.modules = %w{
            RecordSetModule
          }

          klass.collections = %w{
            Dimensions
          }

          klass.properties = %w{
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            Измерения (Dimensions)
            МодульНабораЗаписей (RecordSetModule)
            РежимУправленияБлокировкойДанных (DataLockControlMode)
          }
        end

        add :Enum, :Перечисление do |klass|
          klass.modules = %w{
            ManagerModule
          }

          klass.collections = %w{
            Commands
            Forms
            Templates
            EnumValues
          }

          klass.properties = %w{
            Explanation
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            БыстрыйВыбор (QuickChoice)
            ДополнительнаяФормаДляВыбора (AuxiliaryChoiceForm)
            ДополнительнаяФормаСписка (AuxiliaryListForm)
            ЗначенияПеречисления (EnumValues)
            ИспользоватьСтандартныеКоманды (UseStandardCommands)
            ИсторияВыбораПриВводе (ChoiceHistoryOnInput)
            Команды (Commands)
            Макеты (Templates)
            МодульМенеджера (ManagerModule)
            ОсновнаяФормаДляВыбора (DefaultChoiceForm)
            ОсновнаяФормаСписка (DefaultListForm)
            Пояснение (Explanation)
            ПредставлениеСписка (ListPresentation)
            РасширенноеПредставлениеСписка (ExtendedListPresentation)
            СпособВыбора (ChoiceMode)
            СтандартныеРеквизиты (StandardProperties)
            Формы (Forms)
            Характеристики (Characteristics)
          }
        end

        add :ChartOfCalculationTypes, :ПланВидовРасчета do |klass|
          klass.rights = %w{
            Чтение
            Добавление
            Изменение
            Удаление
            Просмотр
            ИнтерактивноеДобавление
            Редактирование
            ИнтерактивноеУдаление
            ИнтерактивнаяПометкаУдаления
            ИнтерактивноеСнятиеПометкиУдаления
            ИнтерактивноеУдалениеПомеченных
            ВводПоСтроке
            ИнтерактивноеУдалениеПредопределенныхДанных
            ИнтерактивнаяПометкаУдаленияПредопределенныхДанных
            ИнтерактивноеСнятиеПометкиУдаленияПредопределенныхДанных
            ИнтерактивноеУдалениеПомеченныхПредопределенныхДанных
          }

          klass.modules = %w{
            ManagerModule
            ObjectModule
          }

          klass.collections = COLLECTIONS_A_T_F_C_T

          klass.properties = %w{
            Explanation
            ExtendedObjectPresentation
            CodeLength
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            СтандартныеРеквизиты (StandardAttributes)
            СтандартныеТабличныеЧасти (StandardTabularSections)
            БазовыеВидыРасчета (BaseCalculationTypes)
            БыстрыйВыбор (QuickChoice)
            ВводитсяНаОсновании (BasedOn)
            ВводПоСтроке (InputByString)
            ВключатьСправкуВСодержание (IncludeHelpInContents)
            ДлинаКода (CodeLength)
            ДлинаНаименования (DescriptionLength)
            ДополнительнаяФормаДляВыбора (AuxiliaryChoiceForm)
            ДополнительнаяФормаОбъекта (AuxiliaryObjectForm)
            ДополнительнаяФормаСписка (AuxiliaryListForm)
            ДопустимаяДлинаКода (CodeAllowedLength)
            ЗависимостьОтВидовРасчета (DependenceOnCalculationTypes)
            ИспользованиеПериодаДействия (ActionPeriodUse)
            ИспользоватьСтандартныеКоманды (UseStandardCommands)
            ИсторияВыбораПриВводе (ChoiceHistoryOnInput)
            Команды (Commands)
            Макеты (Templates)
            МодульМенеджера (ManagerModule)
            МодульОбъекта (ObjectModule)
            ОбновлениеПредопределенныхДанных (PredefinedDataUpdate)
            ОсновнаяФормаДляВыбора (DefaultChoiceForm)
            ОсновнаяФормаОбъекта (DefaultObjectForm)
            ОсновнаяФормаСписка (DefaultListForm)
            ОсновноеПредставление (DefaultPresentation)
            ПолнотекстовыйПоиск (FullTextSearch)
            ПолнотекстовыйПоискПриВводеПоСтроке (FullTextSearchOnInputByString)
            ПоляБлокировкиДанных (DataLockFields)
            Пояснение (Explanation)
            Предопределенные (Predefined)
            ПредставлениеОбъекта (ObjectPresentation)
            ПредставлениеСписка (ListPresentation)
            РасширенноеПредставлениеОбъекта (ExtendedObjectPresentation)
            РасширенноеПредставлениеСписка (ExtendedListPresentation)
            РежимПолученияДанныхВыбораПриВводеПоСтроке (ChoiceDataGetModeOnInputByString)
            РежимУправленияБлокировкойДанных (DataLockControlMode)
            Реквизиты (Attributes)
            СозданиеПриВводе (CreateOnInput)
            СпособВыбора (ChoiceMode)
            СпособПоискаСтрокиПриВводеПоСтроке (SearchStringModeOnInputByString)
            СпособРедактирования (EditType)
            Справка (Help)
            ТабличныеЧасти (TabularSections)
            ТипКода (CodeType)
            Формы (Forms)
            Характеристики (Characteristics)
          }
        end

        add :ChartOfCharacteristicTypes, :ПланВидовХарактеристик do |klass|
          klass.rights = %w{
            Чтение
            Добавление
            Изменение
            Удаление
            Просмотр
            ИнтерактивноеДобавление
            Редактирование
            ИнтерактивноеУдаление
            ИнтерактивнаяПометкаУдаления
            ИнтерактивноеСнятиеПометкиУдаления
            ИнтерактивноеУдалениеПомеченных
            ВводПоСтроке
            ИнтерактивноеУдалениеПредопределенныхДанных
            ИнтерактивнаяПометкаУдаленияПредопределенныхДанных
            ИнтерактивноеСнятиеПометкиУдаленияПредопределенныхДанных
            ИнтерактивноеУдалениеПомеченныхПредопределенныхДанных
          }

          klass.modules = %w{
            ManagerModule
            ObjectModule
          }

          klass.collections = COLLECTIONS_A_T_F_C_T

          klass.properties = %w{
            Explanation
            ExtendedObjectPresentation
            CodeLength
            Hierarchical
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            СтандартныеРеквизиты (StandardAttributes)
            Автонумерация (Autonumbering)
            БыстрыйВыбор (QuickChoice)
            ВводитсяНаОсновании (BasedOn)
            ВводПоСтроке (InputByString)
            ВключатьСправкуВСодержание (IncludeHelpInContents)
            ГруппыСверху (FoldersOnTop)
            ДлинаКода (CodeLength)
            ДлинаНаименования (DescriptionLength)
            ДополнительнаяФормаГруппы (AuxiliaryFolderForm)
            ДополнительнаяФормаДляВыбора (AuxiliaryChoiceForm)
            ДополнительнаяФормаДляВыбораГруппы (AuxiliaryFolderChoiceForm)
            ДополнительнаяФормаОбъекта (AuxiliaryObjectForm)
            ДополнительнаяФормаСписка (AuxiliaryListForm)
            ДополнительныеЗначенияХарактеристик (CharacteristicExtValues)
            ДопустимаяДлинаКода (CodeAllowedLength)
            Иерархический (Hierarchical)
            ИспользоватьСтандартныеКоманды (UseStandardCommands)
            ИсторияВыбораПриВводе (ChoiceHistoryOnInput)
            Команды (Commands)
            КонтрольУникальности (CheckUnique)
            Макеты (Templates)
            МодульМенеджера (ManagerModule)
            МодульОбъекта (ObjectModule)
            ОбновлениеПредопределенныхДанных (PredefinedDataUpdate)
            ОсновнаяФормаГруппы (DefaultFolderForm)
            ОсновнаяФормаДляВыбора (DefaultChoiceForm)
            ОсновнаяФормаДляВыбораГруппы (DefaultFolderChoiceForm)
            ОсновнаяФормаОбъекта (DefaultObjectForm)
            ОсновнаяФормаСписка (DefaultListForm)
            ОсновноеПредставление (DefaultPresentation)
            ПолнотекстовыйПоиск (FullTextSearch)
            ПолнотекстовыйПоискПриВводеПоСтроке (FullTextSearchOnInputByString)
            ПоляБлокировкиДанных (DataLockFields)
            Пояснение (Explanation)
            Предопределенные (Predefined)
            ПредставлениеОбъекта (ObjectPresentation)
            ПредставлениеСписка (ListPresentation)
            РасширенноеПредставлениеОбъекта (ExtendedObjectPresentation)
            РасширенноеПредставлениеСписка (ExtendedListPresentation)
            РежимПолученияДанныхВыбораПриВводеПоСтроке (ChoiceDataGetModeOnInputByString)
            РежимУправленияБлокировкойДанных (DataLockControlMode)
            Реквизиты (Attributes)
            СерииКодов (CodeSeries)
            СозданиеПриВводе (CreateOnInput)
            СпособВыбора (ChoiceMode)
            СпособПоискаСтрокиПриВводеПоСтроке (SearchStringModeOnInputByString)
            СпособРедактирования (EditType)
            Справка (Help)
            ТабличныеЧасти (TabularSections)
            Тип (Type)
            Формы (Forms)
            Характеристики (Characteristics)
          }
        end

        add :ExchangePlan, :ПланОбмена do |klass|
          klass.rights = %w{
            Чтение
            Добавление
            Изменение
            Удаление
            Просмотр
            ИнтерактивноеДобавление
            Редактирование
            ИнтерактивноеУдаление
            ИнтерактивнаяПометкаУдаления
            ИнтерактивноеСнятиеПометкиУдаления
            ИнтерактивноеУдалениеПомеченных
            ВводПоСтроке
          }

          klass.modules = %w{
            ManagerModule
            ObjectModule
          }

          klass.collections =  COLLECTIONS_A_T_F_C_T

          klass.properties = %w{
            Explanation
            CodeLength
            ExtendedObjectPresentation
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            СтандартныеРеквизиты (StandardAttributes)
            БыстрыйВыбор (QuickChoice)
            ВводитсяНаОсновании (BasedOn)
            ВводПоСтроке (InputByString)
            ВключатьСправкуВСодержание (IncludeHelpInContents)
            ДлинаКода (CodeLength)
            ДлинаНаименования (DescriptionLength)
            ДополнительнаяФормаДляВыбора (AuxiliaryChoiceForm)
            ДополнительнаяФормаОбъекта (AuxiliaryObjectForm)
            ДополнительнаяФормаСписка (AuxiliaryListForm)
            ДопустимаяДлинаКода (CodeAllowedLength)
            ИспользоватьСтандартныеКоманды (UseStandardCommands)
            ИсторияВыбораПриВводе (ChoiceHistoryOnInput)
            Команды (Commands)
            Макеты (Templates)
            МодульМенеджера (ManagerModule)
            МодульОбъекта (ObjectModule)
            ОсновнаяФормаДляВыбора (DefaultChoiceForm)
            ОсновнаяФормаОбъекта (DefaultObjectForm)
            ОсновнаяФормаСписка (DefaultListForm)
            ОсновноеПредставление (DefaultPresentation)
            ПолнотекстовыйПоиск (FullTextSearch)
            ПолнотекстовыйПоискПриВводеПоСтроке (FullTextSearchOnInputByString)
            ПоляБлокировкиДанных (DataLockFields)
            Пояснение (Explanation)
            ПредставлениеОбъекта (ObjectPresentation)
            ПредставлениеСписка (ListPresentation)
            РаспределеннаяИнформационнаяБаза (DistributedInfoBase)
            РасширенноеПредставлениеОбъекта (ExtendedObjectPresentation)
            РасширенноеПредставлениеСписка (ExtendedListPresentation)
            РежимПолученияДанныхВыбораПриВводеПоСтроке (ChoiceDataGetModeOnInputByString)
            РежимУправленияБлокировкойДанных (DataLockControlMode)
            Реквизиты (Attributes)
            СозданиеПриВводе (CreateOnInput)
            Состав (Content)
            СпособВыбора (ChoiceMode)
            СпособПоискаСтрокиПриВводеПоСтроке (SearchStringModeOnInputByString)
            СпособРедактирования (EditType)
            Справка (Help)
            ТабличныеЧасти (TabularSections)
            Формы (Forms)
            Характеристики (Characteristics)
          }
        end

        add :ChartOfAccounts, :ПланСчетов do |klass|
          klass.rights = %w{
            Чтение
            Добавление
            Изменение
            Удаление
            Просмотр
            ИнтерактивноеДобавление
            Редактирование
            ИнтерактивноеУдаление
            ИнтерактивнаяПометкаУдаления
            ИнтерактивноеСнятиеПометкиУдаления
            ИнтерактивноеУдалениеПомеченных
            ВводПоСтроке
            ИнтерактивноеУдалениеПредопределенныхДанных
            ИнтерактивнаяПометкаУдаленияПредопределенныхДанных
            ИнтерактивноеСнятиеПометкиУдаленияПредопределенныхДанных
            ИнтерактивноеУдалениеПомеченныхПредопределенныхДанных
          }

          klass.modules = %w{
            ManagerModule
            ObjectModule
          }

          klass.collections = COLLECTIONS_A_T_F_C_T +
            %w{AccountingFlags ExtDimensionAccountingFlags}

          klass.properties = %w{
            CodeLength
            Explanation
            ExtendedObjectPresentation
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            СтандартныеРеквизиты (StandardAttributes)
            СтандартныеТабличныеЧасти (StandardTabularSections)
            АвтоПорядокПоКоду (AutoOrderByCode)
            БыстрыйВыбор (QuickChoice)
            ВводитсяНаОсновании (BasedOn)
            ВводПоСтроке (InputByString)
            ВидыСубконто (ExtDimensionTypes)
            ВключатьСправкуВСодержание (IncludeHelpInContents)
            ДлинаКода (CodeLength)
            ДлинаНаименования (DescriptionLength)
            ДлинаПорядка (OrderLength)
            ДополнительнаяФормаДляВыбора (AuxiliaryChoiceForm)
            ДополнительнаяФормаОбъекта (AuxiliaryObjectForm)
            ДополнительнаяФормаСписка (AuxiliaryListForm)
            ИспользоватьСтандартныеКоманды (UseStandardCommands)
            ИсторияВыбораПриВводе (ChoiceHistoryOnInput)
            Команды (Commands)
            КонтрольУникальности (CheckUnique)
            Макеты (Templates)
            МаксКоличествоСубконто (MaxExtDimensionCount)
            МаскаКода (CodeMask)
            МодульМенеджера (ManagerModule)
            МодульОбъекта (ObjectModule)
            ОбновлениеПредопределенныхДанных (PredefinedDataUpdate)
            ОсновнаяФормаДляВыбора (DefaultChoiceForm)
            ОсновнаяФормаОбъекта (DefaultObjectForm)
            ОсновнаяФормаСписка (DefaultListForm)
            ОсновноеПредставление (DefaultPresentation)
            ПолнотекстовыйПоиск (FullTextSearch)
            ПолнотекстовыйПоискПриВводеПоСтроке (FullTextSearchOnInputByString)
            ПоляБлокировкиДанных (DataLockFields)
            Пояснение (Explanation)
            Предопределенные (Predefined)
            ПредставлениеОбъекта (ObjectPresentation)
            ПредставлениеСписка (ListPresentation)
            ПризнакиУчета (AccountingFlags)
            ПризнакиУчетаСубконто (ExtDimensionAccountingFlags)
            РасширенноеПредставлениеОбъекта (ExtendedObjectPresentation)
            РасширенноеПредставлениеСписка (ExtendedListPresentation)
            РежимПолученияДанныхВыбораПриВводеПоСтроке (ChoiceDataGetModeOnInputByString)
            РежимУправленияБлокировкойДанных (DataLockControlMode)
            Реквизиты (Attributes)
            СерииКодов (CodeSeries)
            СозданиеПриВводе (CreateOnInput)
            СпособВыбора (ChoiceMode)
            СпособПоискаСтрокиПриВводеПоСтроке (SearchStringModeOnInputByString)
            СпособРедактирования (EditType)
            Справка (Help)
            ТабличныеЧасти (TabularSections)
            Формы (Forms)
            Характеристики (Characteristics)
          }
        end

        add :EventSubscription, :ПодпискаНаСобытие do |klass|
          klass.properties = %w{
            Event
            Handler
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            Источник (Source)
            Обработчик (Handler)
            Событие (Event)
          }
        end

        add :Subsystem, :Подсистема do |klass|
          klass.rights = %w{
            Просмотр
          }

          klass.collections = %w{
            Subsystems
          }

          klass.properties = %w{
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            ВключатьВКомандныйИнтерфейс (IncludeInCommandInterface)
            ВключатьСправкуВСодержание (IncludeHelpInContents)
            Картинка (Picture)
            КомандныйИнтерфейс (CommandInterface)
            Подсистемы (Subsystems)
            Пояснение (Explanation)
            Состав (Content)
            Справка (Help)
          }
        end

        add :Field, :Поле do |klass|
          klass.rights = %w{
            Просмотр
            Редактирование
          }

          klass.properties = %w{
            Tooltip
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            БыстрыйВыбор (QuickChoice)
            ВыделятьОтрицательные (MarkNegatives)
            ЗаполнятьИзДанныхЗаполнения (FillFromFillingValue)
            ЗначениеЗаполнения (FillingValue)
            ИмяВИсточникеДанных (NameInDataSource)
            ИсторияВыбораПриВводе (ChoiceHistoryOnInput)
            Маска (Mask)
            МногострочныйРежим (MultiLine)
            ПараметрыВыбора (ChoiceParameters)
            Подсказка (Tooltip)
            ПроверкаЗаполнения (FillChecking)
            РазрешитьNull (AllowNull)
            РасширенноеРедактирование (ExtendedEdit)
            РежимПароля (PasswordMode)
            СвязиПараметровВыбора (ChoiceParameterLinks)
            СозданиеПриВводе (CreateOnInput)
            Тип (Type)
            ТолькоЧтение (ReadOnly)
            ФормаВыбора (ChoiceForm)
            Формат (Format)
            ФорматРедактирования (EditFormat)
          }
        end

        add :Sequence, :Последовательность do |klass|
          klass.rights = %w{
            Чтение
            Изменение
          }

          klass.modules = %w{
            RecordSetModule
          }

          klass.collections = %w{
            Dimensions
          }
          klass.properties = %w{
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            Движения (RegisterRecords)
            Документы (Documents)
            Измерения (Dimensions)
            МодульНабораЗаписей (RecordSetModule)
            ПеремещениеГраницыПриПроведении (MoveBoundaryOnPosting)
            РежимУправленияБлокировкойДанных (DataLockControlMode)
          }
        end

        add :AccountingFlag, :ПризнакУчетаПланаСчетов do |klass|
          klass.rights = %w{
            Просмотр
            Редактирование
          }

          klass.properties = %w{
            Tooltip
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            БыстрыйВыбор (QuickChoice)
            ВыборГруппИЭлементов (ChoiceFoldersAndItems)
            ВыделятьОтрицательные (MarkNegatives)
            ЗаполнятьИзДанныхЗаполнения (FillFromFillingValue)
            ИсторияВыбораПриВводе (ChoiceHistoryOnInput)
            Маска (Mask)
            МногострочныйРежим (MultiLine)
            Подсказка (Tooltip)
            ПроверкаЗаполнения (FillChecking)
            РасширенноеРедактирование (ExtendedEdit)
            РежимПароля (PasswordMode)
            СозданиеПриВводе (CreateOnInput)
            Тип (Type)
            ФормаВыбора (ChoiceForm)
            Формат (Format)
            ФорматРедактирования (EditFormat)
          }
        end

        add :ExtDimensionAccountingFlag, :ПризнакУчетаСубконтоПланаСчетов do |klass|
          klass.rights = %w{
            Просмотр
            Редактирование
          }

          klass.properties = %w{
            Tooltip
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            БыстрыйВыбор (QuickChoice)
            ВыборГруппИЭлементов (ChoiceFoldersAndItems)
            ВыделятьОтрицательные (MarkNegatives)
            ЗаполнятьИзДанныхЗаполнения (FillFromFillingValue)
            ИсторияВыбораПриВводе (ChoiceHistoryOnInput)
            Маска (Mask)
            МногострочныйРежим (MultiLine)
            Подсказка (Tooltip)
            ПроверкаЗаполнения (FillChecking)
            РасширенноеРедактирование (ExtendedEdit)
            РежимПароля (PasswordMode)
            СозданиеПриВводе (CreateOnInput)
            Тип (Type)
            ФормаВыбора (ChoiceForm)
            Формат (Format)
            ФорматРедактирования (EditFormat)
          }
        end

        add :AccountingRegister, :РегистрБухгалтерии do |klass|
          klass.rights = %w{
            Чтение
            Изменение
            Просмотр
            Редактирование
            УправлениеИтогами
          }

          klass.modules = %w{
            ManagerModule
            RecordSetModule
          }

          klass.collections = %w{
            Dimensions
            Resources
            Attributes
            Forms
            Commands
            Templates
          }

          klass.properties = %w{
            Explanation
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            СтандартныеРеквизиты (StandardAttributes)
            ВключатьСправкуВСодержание (IncludeHelpInContents)
            ДополнительнаяФормаСписка (AuxiliaryListForm)
            Измерения (Dimensions)
            ИспользоватьСтандартныеКоманды (UseStandardCommands)
            Команды (Commands)
            Корреспонденция (Correspondence)
            Макеты (Templates)
            МодульМенеджера (ManagerModule)
            МодульНабораЗаписей (RecordSetModule)
            ОсновнаяФормаСписка (DefaultListForm)
            ПланСчетов (ChartOfAccounts)
            ПолнотекстовыйПоиск (FullTextSearch)
            Пояснение (Explanation)
            ПредставлениеСписка (ListPresentation)
            РазрешитьРазделениеИтогов (EnableTotalsSplitting)
            РасширенноеПредставлениеСписка (ExtendedListPresentation)
            РежимУправленияБлокировкойДанных (DataLockControlMode)
            Реквизиты (Attributes)
            Ресурсы (Resources)
            Справка (Help)
            Формы (Forms)
          }

        end

        add :AccumulationRegister, :РегистрНакопления do |klass|
          klass.rights = %w{
            Чтение
            Изменение
            Просмотр
            Редактирование
            УправлениеИтогами
          }

          klass.modules = %w{
            ManagerModule
            RecordSetModule
          }

          klass.collections = %w{
            Dimensions
            Resources
            Attributes
            Forms
            Commands
            Templates
          }

          klass.properties = %w{
            Explanation
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            СтандартныеРеквизиты (StandardAttributes)
            Агрегаты (Aggregates)
            ВидРегистра (RegisterType)
            ВключатьСправкуВСодержание (IncludeHelpInContents)
            ДополнительнаяФормаСписка (AuxiliaryListForm)
            Измерения (Dimensions)
            ИспользоватьСтандартныеКоманды (UseStandardCommands)
            Команды (Commands)
            Макеты (Templates)
            МодульМенеджера (ManagerModule)
            МодульНабораЗаписей (RecordSetModule)
            ОсновнаяФормаСписка (DefaultListForm)
            ПолнотекстовыйПоиск (FullTextSearch)
            Пояснение (Explanation)
            ПредставлениеСписка (ListPresentation)
            РазрешитьРазделениеИтогов (EnableTotalsSplitting)
            РасширенноеПредставлениеСписка (ExtendedListPresentation)
            РежимУправленияБлокировкойДанных (DataLockControlMode)
            Реквизиты (Attributes)
            Ресурсы (Resources)
            Справка (Help)
            Формы (Forms)
          }
        end

        add :CalculationRegister, :РегистрРасчета do |klass|
          klass.rights = %w{
            Чтение
            Изменение
            Просмотр
            Редактирование
          }

          klass.modules = %w{
            ManagerModule
            RecordSetModule
          }

          klass.collections = %w{
            Dimensions
            Resources
            Attributes
            Forms
            Commands
            Templates
            Recalculations
          }

          klass.properties = %w{
            Explanation
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            СтандартныеРеквизиты (StandardAttributes)
            БазовыйПериод (BasePeriod)
            ВключатьСправкуВСодержание (IncludeHelpInContents)
            График (Schedule)
            ДатаГрафика (ScheduleDate)
            ДополнительнаяФормаСписка (AuxiliaryListForm)
            ЗначениеГрафика (ScheduleValue)
            Измерения (Dimensions)
            ИспользоватьСтандартныеКоманды (UseStandardCommands)
            Команды (Commands)
            Макеты (Templates)
            МодульМенеджера (ManagerModule)
            МодульНабораЗаписей (RecordSetModule)
            ОсновнаяФормаСписка (DefaultListForm)
            Перерасчеты (Recalculations)
            ПериодДействия (ActionPeriod)
            Периодичность (Periodicity)
            ПланВидовРасчета (ChartOfCalculationTypes)
            ПолнотекстовыйПоиск (FullTextSearch)
            Пояснение (Explanation)
            ПредставлениеСписка (ListPresentation)
            РасширенноеПредставлениеСписка (ExtendedListPresentation)
            РежимУправленияБлокировкойДанных (DataLockControlMode)
            Реквизиты (Attributes)
            Ресурсы (Resources)
            Справка (Help)
            Формы (Forms)
          }
        end

        add :InformationRegister, :РегистрСведений do |klass|
          klass.rights = %w{
            Чтение
            Изменение
            Просмотр
            Редактирование
            УправлениеИтогами
          }

          klass.modules = %w{
            ManagerModule
            RecordSetModule
          }

          klass.collections = %w{
            Dimensions
            Resources
            Attributes
            Forms
            Commands
            Templates
          }

          klass.properties = %w{
            Explanation
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            СтандартныеРеквизиты (StandardAttributes)
            ВключатьСправкуВСодержание (IncludeHelpInContents)
            ДополнительнаяФормаЗаписи (AuxiliaryRecordForm)
            ДополнительнаяФормаСписка (AuxiliaryListForm)
            Измерения (Dimensions)
            ИспользоватьСтандартныеКоманды (UseStandardCommands)
            Команды (Commands)
            Макеты (Templates)
            МодульМенеджера (ManagerModule)
            МодульНабораЗаписей (RecordSetModule)
            ОсновнаяФормаЗаписи (DefaultRecordForm)
            ОсновнаяФормаСписка (DefaultListForm)
            ОсновнойОтборПоПериоду (MainFilterOnPeriod)
            ПериодичностьРегистраСведений (InformationRegisterPeriodicity)
            ПолнотекстовыйПоиск (FullTextSearch)
            Пояснение (Explanation)
            ПредставлениеЗаписи (RecordPresentation)
            ПредставлениеСписка (ListPresentation)
            РазрешитьИтогиСрезПервых (EnableTotalsSliceFirst)
            РазрешитьИтогиСрезПоследних (EnableTotalsSliceLast)
            РасширенноеПредставлениеЗаписи (ExtendedRecordPresentation)
            РасширенноеПредставлениеСписка (ExtendedListPresentation)
            РежимЗаписи (WriteMode)
            РежимУправленияБлокировкойДанных (DataLockControlMode)
            Реквизиты (Attributes)
            Ресурсы (Resources)
            СпособРедактирования (EditType)
            Справка (Help)
            Формы (Forms)
          }
        end

        add :ScheduledJob, :РегламентноеЗадание do |klass|
          klass.properties = %w{
            Predefined
            MethodName
            Use
            Key
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            ИмяМетода (MethodName)
            ИнтервалПовтораПриАварийномЗавершении (RestartIntervalOnFailure)
            Использование (Use)
            Ключ (Key)
            КоличествоПовторовПриАварийномЗавершении (RestartCountOnFailure)
            Наименование (Description)
            Предопределенное (Predefined)
            Расписание (Schedule)
          }
        end

        add :AddressingAttribute, :РеквизитАдресации do |klass|
          klass.rights = %w{
            Просмотр
            Редактирование
          }

          klass.properties = %w{
            Tooltip
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            БыстрыйВыбор (QuickChoice)
            ВыборГруппИЭлементов (ChoiceFoldersAndItems)
            ВыделятьОтрицательные (MarkNegatives)
            ЗаполнятьИзДанныхЗаполнения (FillFromFillingValue)
            ИзмерениеАдресации (AddressingDimension)
            Индексирование (Indexing)
            ИсторияВыбораПриВводе (ChoiceHistoryOnInput)
            Маска (Mask)
            МногострочныйРежим (MultiLine)
            ПараметрыВыбора (ChoiceParameters)
            Подсказка (Tooltip)
            ПолнотекстовыйПоиск (FullTextSearch)
            ПроверкаЗаполнения (FillChecking)
            РасширенноеРедактирование (ExtendedEdit)
            РежимПароля (PasswordMode)
            СвязиПараметровВыбора (ChoiceParameterLinks)
            СвязьПоТипу (LinkByType)
            СозданиеПриВводе (CreateOnInput)
            Тип (Type)
            ФормаВыбора (ChoiceForm)
            Формат (Format)
            ФорматРедактирования (EditFormat)
          }
        end

        add :Attribute, :Реквизит do |klass|
          klass.rights = %w{
            Просмотр
            Редактирование
          }

          klass.properties = %w{
            Tooltip
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            БыстрыйВыбор (QuickChoice)
            ВыборГруппИЭлементов (ChoiceFoldersAndItems)
            ВыделятьОтрицательные (MarkNegatives)
            ЗаполнятьИзДанныхЗаполнения (FillFromFillingValue)
            ЗначениеЗаполнения (FillingValue)
            Индексирование (Indexing)
            Использование (Use)
            ИсторияВыбораПриВводе (ChoiceHistoryOnInput)
            МаксимальноеЗначение (MaxValue)
            Маска (Mask)
            МинимальноеЗначение (MinValue)
            МногострочныйРежим (MultiLine)
            ПараметрыВыбора (ChoiceParameters)
            Подсказка (Tooltip)
            ПолнотекстовыйПоиск (FullTextSearch)
            ПроверкаЗаполнения (FillChecking)
            РасширенноеРедактирование (ExtendedEdit)
            РежимПароля (PasswordMode)
            СвязиПараметровВыбора (ChoiceParameterLinks)
            СвязьПоТипу (LinkByType)
            СозданиеПриВводе (CreateOnInput)
            Тип (Type)
            ФормаВыбора (ChoiceForm)
            Формат (Format)
            ФорматРедактирования (EditFormat)
          }
        end

        add :Resource, :Ресурс do |klass|
          klass.rights = %w{
            Просмотр
            Редактирование
          }

          klass.properties = %w{
            Tooltip
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            Балансовый (Balance)
            БыстрыйВыбор (QuickChoice)
            ВыборГруппИЭлементов (ChoiceFoldersAndItems)
            ВыделятьОтрицательные (MarkNegatives)
            ЗаполнятьИзДанныхЗаполнения (FillFromFillingValue)
            Индексирование (Indexing)
            ИсторияВыбораПриВводе (ChoiceHistoryOnInput)
            Маска (Mask)
            МногострочныйРежим (MultiLine)
            ПараметрыВыбора (ChoiceParameters)
            Подсказка (Tooltip)
            ПолнотекстовыйПоиск (FullTextSearch)
            ПризнакУчета (AccountingFlag)
            ПризнакУчетаСубконто (ExtDimensionAccountingFlag)
            ПроверкаЗаполнения (FillChecking)
            РасширенноеРедактирование (ExtendedEdit)
            РежимПароля (PasswordMode)
            СвязиПараметровВыбора (ChoiceParameterLinks)
            СвязьПоТипу (LinkByType)
            СозданиеПриВводе (CreateOnInput)
            Тип (Type)
            ФормаВыбора (ChoiceForm)
            Формат (Format)
            ФорматРедактирования (EditFormat)
          }
        end

        add :Role, :Роль do |klass|
          klass.properties = %w{
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            Права (Rights)
          }
        end

        add :Catalog, :Справочник do |klass|
          klass.rights = %w{
            Чтение
            Добавление
            Изменение
            Удаление
            Просмотр
            ИнтерактивноеДобавление
            Редактирование
            ИнтерактивноеУдаление
            ИнтерактивнаяПометкаУдаления
            ИнтерактивноеСнятиеПометкиУдаления
            ИнтерактивноеУдалениеПомеченных
            ВводПоСтроке
            ИнтерактивноеУдалениеПредопределенныхДанных
            ИнтерактивнаяПометкаУдаленияПредопределенныхДанных
            ИнтерактивноеСнятиеПометкиУдаленияПредопределенныхДанных
            ИнтерактивноеУдалениеПомеченныхПредопределенныхДанных
          }

          klass.modules = %w{
            ManagerModule
            ObjectModule
          }

          klass.collections = COLLECTIONS_A_T_F_C_T

          klass.properties = %w{
            CodeLength
            Hierarchical
            CheckUnique
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            СтандартныеРеквизиты (StandardAttributes)
            Автонумерация (Autonumbering)
            БыстрыйВыбор (QuickChoice)
            ВводитсяНаОсновании (BasedOn)
            ВводПоСтроке (InputByString)
            ВидИерархии (HierarchyType)
            ВключатьСправкуВСодержание (IncludeHelpInContents)
            Владельцы (Owners)
            ГруппыСверху (FoldersOnTop)
            ДлинаКода (CodeLength)
            ДлинаНаименования (DescriptionLength)
            ДополнительнаяФормаГруппы (AuxiliaryFolderForm)
            ДополнительнаяФормаДляВыбора (AuxiliaryChoiceForm)
            ДополнительнаяФормаДляВыбораГруппы (AuxiliaryFolderChoiceForm)
            ДополнительнаяФормаОбъекта (AuxiliaryObjectForm)
            ДополнительнаяФормаСписка (AuxiliaryListForm)
            ДопустимаяДлинаКода (CodeAllowedLength)
            Иерархический (Hierarchical)
            ИспользованиеПодчинения (SubordinationUse)
            ИспользоватьСтандартныеКоманды (UseStandardCommands)
            ИсторияВыбораПриВводе (ChoiceHistoryOnInput)
            КоличествоУровней (LevelCount)
            Команды (Commands)
            КонтрольУникальности (CheckUnique)
            Макеты (Templates)
            МодульМенеджера (ManagerModule)
            МодульОбъекта (ObjectModule)
            ОбновлениеПредопределенныхДанных (PredefinedDataUpdate)
            ОграничиватьКоличествоУровней (LimitLevelCount)
            ОсновнаяФормаГруппы (DefaultFolderForm)
            ОсновнаяФормаДляВыбора (DefaultChoiceForm)
            ОсновнаяФормаДляВыбораГруппы (DefaultFolderChoiceForm)
            ОсновнаяФормаОбъекта (DefaultObjectForm)
            ОсновнаяФормаСписка (DefaultListForm)
            ОсновноеПредставление (DefaultPresentation)
            ПолнотекстовыйПоиск (FullTextSearch)
            ПолнотекстовыйПоискПриВводеПоСтроке (FullTextSearchOnInputByString)
            ПоляБлокировкиДанных (DataLockFields)
            Пояснение (Explanation)
            Предопределенные (Predefined)
            ПредставлениеОбъекта (ObjectPresentation)
            ПредставлениеСписка (ListPresentation)
            РасширенноеПредставлениеОбъекта (ExtendedObjectPresentation)
            РасширенноеПредставлениеСписка (ExtendedListPresentation)
            РежимПолученияДанныхВыбораПриВводеПоСтроке (ChoiceDataGetModeOnInputByString)
            РежимУправленияБлокировкойДанных (DataLockControlMode)
            Реквизиты (Attributes)
            СерииКодов (CodeSeries)
            СозданиеПриВводе (CreateOnInput)
            СпособВыбора (ChoiceMode)
            СпособПоискаСтрокиПриВводеПоСтроке (SearchStringModeOnInputByString)
            СпособРедактирования (EditType)
            Справка (Help)
            ТабличныеЧасти (TabularSections)
            ТипКода (CodeType)
            Формы (Forms)
            Характеристики (Characteristics)
          }

        end

        add :Style, :Стиль do |klass|
          klass.properties = %w{
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            Стиль (Style)
          }
        end

        add :StyleItem, :ЭлементСтиля do |klass|
          klass.properties = %w{
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            Вид (Type)
            Значение (Value)
          }
        end

        add :DimensionTable, :ТаблицаИзмерения do |klass|
          klass.rights = %w{
            Чтение
            Просмотр
          }

          klass.modules = %w{
            ManagerModule
            ObjectModule
          }

          klass.collections = %w{
            Fields
            Forms
            Templates
            Commands
          }

          klass.properties = %w{
            Explanation
            Hierarchical
            NameInDataSource
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            БыстрыйВыбор (QuickChoice)
            ВключатьСправкуВСодержание (IncludeHelpInContents)
            ЗначениеНезаполненногоРодителя (UnfilledParentValue)
            Иерархическая (Hierarchical)
            ИмяВИсточникеДанных (NameInDataSource)
            ИмяИерархииВИсточникеДанных (HierarchyNameInDataSource)
            ИспользоватьСтандартныеКоманды (UseStandardCommands)
            Макеты (Templates)
            МодульМенеджера (ManagerModule)
            МодульОбъекта (ObjectModule)
            НомерУровня (LevelNumber)
            ОсновнаяФормаДляВыбора (DefaultChoiceForm)
            ОсновнаяФормаОбъекта (DefaultObjectForm)
            ОсновнаяФормаСписка (DefaultListForm)
            ПолеПредставления (PresentationField)
            Поля (Fields)
            Пояснение (Explanation)
            ПредставлениеОбъекта (ObjectPresentation)
            ПредставлениеСписка (ListPresentation)
            РасширенноеПредставлениеОбъекта (ExtendedObjectPresentation)
            РасширенноеПредставлениеСписка (ExtendedListPresentation)
            Справка (Help)
            Формы (Forms)
            Команды (Commands)
          }
        end

        add :Table, :Таблица do |klass|
          klass.rights = %w{
            Чтение
            Просмотр
            ВводПоСтроке
          }

          klass.modules = %w{
            ManagerModule
            RecordSetModule
          }

          klass.collections = %w{
            Commands
            Fields
            Templates
            Forms
          }

          klass.properties = %w{
            Explanation
            NameInDataSource
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            БыстрыйВыбор (QuickChoice)
            ВводитсяНаОсновании (BasedOn)
            ВводПоСтроке (InputByString)
            ВидТаблицы (TableType)
            ВключатьСправкуВСодержание (IncludeHelpInContents)
            ВыражениеВИсточникеДанных (ExpressionInDataSource)
            ЗначениеНезаполненногоРодителя (UnfilledParentValue)
            ИмяВИсточникеДанных (NameInDataSource)
            ИспользоватьСтандартныеКоманды (UseStandardCommands)
            ИсторияВыбораПриВводе (ChoiceHistoryOnInput)
            Команды (Commands)
            Макеты (Templates)
            МодульМенеджера (ManagerModule)
            МодульНабораЗаписей (RecordSetModule)
            МодульОбъекта (ObjectModule)
            ОсновнаяФормаДляВыбора (DefaultChoiceForm)
            ОсновнаяФормаЗаписи (DefaultRecordForm)
            ОсновнаяФормаОбъекта (DefaultObjectForm)
            ОсновнаяФормаСписка (DefaultListForm)
            ПолеВерсииДанных (DataVersionField)
            ПолеПредставления (PresentationField)
            ПолеРодителя (ParentField)
            Поля (Fields)
            ПоляБлокировкиДанных (DataLockFields)
            ПоляКлюча (KeyFields)
            Пояснение (Explanation)
            ПредставлениеЗаписи (RecordPresentation)
            ПредставлениеОбъекта (ObjectPresentation)
            ПредставлениеСписка (ListPresentation)
            РасширенноеПредставлениеЗаписи (ExtendedRecordPresentation)
            РасширенноеПредставлениеОбъекта (ExtendedObjectPresentation)
            РасширенноеПредставлениеСписка (ExtendedListPresentation)
            РежимПолученияДанныхВыбораПриВводеПоСтроке (ChoiceDataGetModeOnInputByString)
            РежимУправленияБлокировкойДанных (DataLockControlMode)
            СозданиеПриВводе (CreateOnInput)
            СпособПоискаСтрокиПриВводеПоСтроке (SearchStringModeOnInputByString)
            СпособРедактирования (EditType)
            Справка (Help)
            ТипДанныхТаблицы (TableDataType)
            ТолькоЧтение (ReadOnly)
            УровеньИзоляцииТранзакций (TransactionsIsolationLevel)
            Формы (Forms)
            Характеристики (Characteristics)
          }
        end

        add :TabularSection, :ТабличнаяЧасть do |klass|
          klass.rights = %w{
            Просмотр
            Редактирование
          }

          klass.collections = %w{
            Attributes
          }

          klass.properties = %w{
            Tooltip
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            Использование (Use)
            Подсказка (Tooltip)
            ПроверкаЗаполнения (FillChecking)
            Реквизиты (Attributes)
            СтандартныеРеквизиты (StandardProperties)
          }
        end

        add :Form, :Форма do |klass|
          klass.rights = %w{
            Просмотр
          }

          klass.modules = %w{
            Module
          }

          klass.properties = %w{
            Explanation
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            ВключатьСправкуВСодержание (IncludeHelpInContents)
            НазначенияИспользования (UsePurposes)
            Пояснение (Explanation)
            РасширенноеПредставление (ExtendedPresentation)
            Справка (Help)
            ТипФормы (FormType)
            Форма (Form)
          }
        end

        add :FunctionalOption, :ФункциональнаяОпция do |klass|
          klass.properties = %w{
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            ПривилегированныйРежимПриПолучении (PrivilegedGetMode)
            Состав (Content)
            Хранение (Location)
          }
        end

        add :Function, :Функция do |klass|
          klass.rights = %w{
            Использование
            Просмотр
          }

          klass.properties = %w{
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            ВозвращаетЗначение (ReturnValue)
            ВыражениеВИсточникеДанных (ExpressionInDataSource)
            Тип (Type)
          }
        end

        add :SettingsStorage, :ХранилищеНастроек do |klass|
          klass.modules = %w{
            ManagerModule
          }

          klass.collections = %w{
            Forms
            Templates
          }

          klass.properties = %w{
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            ДополнительнаяФормаЗагрузки (AuxiliaryLoadForm)
            ДополнительнаяФормаСохранения (AuxiliarySaveForm)
            Макеты (Templates)
            МодульМенеджера (ManagerModule)
            ОсновнаяФормаЗагрузки (DefaultLoadForm)
            ОсновнаяФормаСохранения (DefaultSaveForm)
            Формы (Forms)
          }
        end

        add :Language, :Язык do |klass|
          klass.properties = %w{
            LanguageCode
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            КодЯзыка (LanguageCode)
          }
        end

        add :HTTPService, :HTTPСервис do |klass|
          klass.modules = %w{
            Module
          }

          klass.collections = %w{
            URLTemplates
          }

          klass.properties = %w{
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            ВремяЖизниСеанса (SessionMaxAge)
            КорневойURL (RootURL)
            Модуль (Module)
            ПовторноеИспользованиеСеансов (ReuseSessions)
            ШаблоныURL (URLTemplates)
          }
        end

        add :WebService, :WebСервис do |klass|
          klass.modules = %w{
            Module
          }

          klass.collections = %w{
            Operations
          }

          klass.properties = %w{
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            ВремяЖизниСеанса (SessionMaxAge)
            ИмяФайлаПубликации (DescriptorFileName)
            Модуль (Module)
            Операции (Operations)
            ПакетыXDTO (XDTOPackages)
            ПовторноеИспользованиеСеансов (ReuseSessions)
            ПространствоИмен (Namespace)
          }
        end

        add :WSReference, :WSСсылка do |klass|
          klass.properties = %w{
          }

          klass.raw_props = %{
            Имя (Name)
            Комментарий (Comment)
            ПринадлежностьОбъекта (ObjectBelonging)
            Синоним (Synonym)
            URLИсточника (LocationURL)
            WSОпределение (WSDefinition)
          }
        end

        add :HttpServiceMethod, :МетодHTTPСервиса  do |klass|
          klass.rights = %w{
            Использование
          }

          klass.properties = %w{
            Handler
          }

          klass.raw_props = %{
            HTTPМетод (HTTPMethod)
            Обработчик (Handler)
          }
        end
      end
    end
  end
end
