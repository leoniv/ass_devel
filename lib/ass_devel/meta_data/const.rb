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
          self.en = en
          self.ru = ru
          self.module_ = module_
          self.class.dict[en] = ru
          self.class.dict[ru] = en
        end

        def self.dict
          @dict ||= {}
        end

        def const_name
          "#{module_}::#{en}"
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
      end

      module Rights
        class Right < RuEnNamed
          include IncludedInMdClass
        end
        extend HaveContent

        def self.klass
          Right
        end

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
          :ИнтерактивноеСнятиеПометкиУдаленияПредопределенных
        add :InteractiveDeleteMarkedPredefinedData,
          :ИнтерактивноеУдалениеПомеченныхПредопределенныхДан
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

          class String < Abstract; end
          class Boolean < Abstract; end
          class Number < Abstract; end
          class ReturnValuesReuse < Enum
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

      module MdProperties
        class Prop < RuEnNamed
          attr_accessor :type
          def initialize(en, ru, type, module_)
            super en, ru, module_
            self.type = PropTypes.get(type)
          end
        end

        extend HaveContent

        def self.klass
          Prop
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
      end

      module MdCollections
        class MdCollection < RuEnNamed
          include IncludedInMdClass
          attr_accessor :md_class_name
          def initialize(en, ru, md_class_name, module_)
            super en, ru, module_
            self.md_class_name = md_class_name
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
        add :CommonForms, :ОбщиеФормы, :CommonForm
        add :CommonCommands, :ОбщиеКоманды, :CommonCommand
        add :CommandGroups, :ГруппыКоманд, :CommandGroup
        add :CommonTemplates, :ОбщиеМакеты, :CommonTemplate
        add :CommonPictures, :ОбщиеКартинки, :CommonPicture
        add :XDTOPackages, :ПакетыXDTO, :XDTOPackage
        add :WebServices, :WebСервисы, :WebService
        add :WSReferences, :WSСсылки, :WSReference
        add :StyleItems, :ЭлементыСтиля, :StyleItem

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
        add :BusinessProcesses, :БизнесПроцессы, :BusinessProcesse
        add :Tasks, :Задачи, :Task

        add :Forms, :Формы, :Form
      end

      module MdClasses
        extend HaveContent

        def self.klass
          MdClass
        end

        class MdClass < RuEnNamed
          DEF_PROPS = %w{Name Synonym Comment}
          attr_writer :top_object
          attr_writer :db_storable

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
            @properties = add_array (arr + DEF_PROPS), MdProperties
          end

          def properties
            @properties ||= []
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

          def top_object?
            @top_object
          end

          def db_storable?
            @db_storable
          end

          def all_included
            rights + collections + modules + properties
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

          klass.collections = %w{CommonModules
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
        end
      end
    end
  end
end
