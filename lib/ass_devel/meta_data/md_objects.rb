module AssDevel
  module MetaData
    module MdObjects
      # All classes must be subclass of {Abstract::TopMdObject}
      module Internal
        class CommonModule < Abstract::TopMdObject
          include Mixins::CommonModule
          include MdContainer::TerminatedMdObject
        end

        class DataProcessor < Abstract::TopMdObject
          'TODO:'
        end

        class Report < Abstract::TopMdObject
          'TODO:'
        end
      end

      # All classes must be subclass of {Abstract::NestedMdObject}
      module Nested
        class Attribute < Abstract::NestedMdObject
          'TODO:'
        end
      end

      # Consists only tow class DataProcessor and Report
      module External
        class DataProcessor < Abstract::NestedMdObject
          'TODO:'
        end

        class Report < Abstract::NestedMdObject
          'TODO:'
        end
      end
    end
  end
end
