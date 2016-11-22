module AssDevel
  module MetaData
    module Const
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
      module Rights
        class Right < RuEnNamed; end
        def self.right(en, ru)
          r = Right.new(en, ru, self)
          const_set en, r
          content << r
        end

        def self.content
          @content ||= []
        end

        def self.get(en_ru)
          content.select {|r| r.en == en_ru || r.ru == en_ru}[0]
        end

        right :InteractiveInsert, :ИнтерактивноеДобавление
        right :Edit, :Редактирование
        right :InteractiveSetDeletionMark, :ИнтерактивнаяПометкаУдаления
        right :InteractiveClearDeletionMark, :ИнтерактивноеСнятиеПометкиУдаления
        right :InteractiveDeleteMarked, :ИнтерактивноеУдалениеПомеченных
        right :InteractivePosting, :ИнтерактивноеПроведение
        right :InteractivePostingRegular, :ИнтерактивноеПроведениеНеОперативное
        right :InteractiveUndoPosting, :ИнтерактивнаяОтменаПроведения
        right :InteractiveChangeOfPosted, :ИнтерактивноеИзменениеПроведенных
        right :InputByString, :ВводПоСтроке
        right :TotalsControl, :УправлениеИтогами
        right :Use, :Использование
        right :InteractiveDelete, :ИнтерактивноеУдаление
        right :Administration, :Администрирование
        right :DataAdministration, :АдминистрированиеДанных
        right :ExclusiveMode, :МонопольныйРежим
        right :ActiveUsers, :АктивныеПользователи
        right :EventLog, :ЖурналРегистрации
        right :ExternalConnection, :ВнешнееСоединение
        right :Automation, :Automation
        right :InteractiveOpenExtDataProcessors, :ИнтерактивноеОткрытиеВнешнихОбработок
        right :InteractiveOpenExtReports, :ИнтерактивноеОткрытиеВнешнихОтчетов
        right :Get, :Получение
        right :Set, :Установка
        right :InteractiveActivate, :ИнтерактивнаяАктивация
        right :Start, :Старт
        right :InteractiveStart, :ИнтерактивныйСтарт
        right :Execute, :Выполнение
        right :InteractiveExecute, :ИнтерактивноеВыполнение
        right :Output, :Вывод
        right :UpdateDataBaseConfiguration, :ОбновлениеКонфигурацииБазыДанных
        right :ThinClient, :ТонкийКлиент
        right :WebClient, :ВебКлиент
        right :ThickClient, :ТолстыйКлиент
        right :AllFunctionsMode, :РежимВсеФункции
        right :SaveUserData, :СохранениеДанныхПользователя
        right :StandardAuthenticationChange, :ИзменениеСтандартнойАутентификации
        right :SessionStandardAuthenticationChange,
          :ИзменениеСтандартнойАутентификацииСеанса
        right :SessionOSAuthenticationChange,
          :ИзменениеАутентификацииОССеанса
        right :InteractiveDeletePredefinedData,
          :ИнтерактивноеУдалениеПредопределенныхДанных
        right :InteractiveSetDeletionMarkPredefinedData,
          :ИнтерактивнаяПометкаУдаленияПредопределенныхДанных
        right :InteractiveClearDeletionMarkPredefinedData,
          :ИнтерактивноеСнятиеПометкиУдаленияПредопределенных
        right :InteractiveDeleteMarkedPredefinedData,
          :ИнтерактивноеУдалениеПомеченныхПредопределенныхДан
        right :ConfigExtensionsAdministration,
          :АдминистрированиеРасширенийКонфигурации
      end
    end

    module MdClasses

    end
  end
end
