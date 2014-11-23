require 'roo/excelx/extractor'

module Roo
  class Excelx::Workbook < Excelx::Extractor
    class Label
      attr_reader :sheet, :row, :col, :name

      def initialize(name, sheet, row, col)
        @name = name
        @sheet = sheet
        @row = row.to_i
        @col = Roo::Base.letter_to_number(col)
      end

      def key
        [@row, @col]
      end
    end

    def initialize(path)
      super
      if !doc_exists?
        raise ArgumentError, 'missing required workbook file'
      end
    end

    def sheets
      doc.xpath("//sheet")
    end

    # aka labels
    def defined_names
      Hash[doc.xpath("//definedName").map do |defined_name|
        # "Sheet1!$C$5"
        sheet, coordinates = defined_name.text.split('!$', 2)
        col,row = coordinates.split('$')
        name = defined_name['name']
        [name, Label.new(name, sheet,row,col)]
      end]
    end

    def base_date
      @base_date ||=
        begin
          # Default to 1900 (minus one day due to excel quirk) but use 1904 if
          # it's set in the Workbook's workbookPr
          # http://msdn.microsoft.com/en-us/library/ff530155(v=office.12).aspx
          result = Date.new(1899,12,30) # default
          doc.xpath("//workbookPr[date1904]").each do |workbookPr|
            if workbookPr["date1904"] =~ /true|1/i
              result = Date.new(1904,01,01)
              break
            end
          end
          result
        end
    end
  end
end