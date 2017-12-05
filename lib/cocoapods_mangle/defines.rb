module CocoapodsMangle
  module Defines
    def self.mangling_defines(prefix, binaries_to_mangle)
      classes = classes(binaries_to_mangle)
      constants = constants(binaries_to_mangle)
      category_selectors = category_selectors(binaries_to_mangle)

      defines = prefix_symbols(prefix, classes)
      defines += prefix_symbols(prefix, constants)
      defines += prefix_selectors(prefix, category_selectors)
      defines
    end

    def self.classes(binaries)
      all_symbols = run_nm(binaries, '-gU')
      class_symbols = all_symbols.select do |symbol|
        symbol[/OBJC_CLASS_\$_/]
      end
      class_symbols = class_symbols.map { |klass| klass.gsub(/^.*\$_/, '') }
      class_symbols.uniq
    end

    def self.constants(binaries)
      all_symbols = run_nm(binaries, '-gU')
      consts = all_symbols.select { |const| const[/ S /] }
      consts = consts.reject { |const| const[/_OBJC_/] }
      consts = consts.map! { |const| const.gsub(/^.* _/, '') }
      consts = consts.uniq

      other_consts = all_symbols.select { |const| const[/ T /] }
      other_consts = other_consts.map! { |const| const.gsub(/^.* _/, '') }
      other_consts = other_consts.uniq

      consts + other_consts
    end

    def self.category_selectors(binaries)
      symbols = run_nm(binaries, '-U')
      selectors = symbols.select { |selector| selector[/ t [-|+]\[[^ ]*\([^ ]*\) [^ ]*\]/] }
      selectors = selectors.map { |selector| selector[/[^ ]*\]\z/][0...-1] }
      selectors = selectors.map { |selector| selector.split(':').first }
      selectors.uniq
    end

    def self.prefix_symbols(prefix, symbols)
      symbols.map do |symbol|
        "#{symbol}=#{prefix}#{symbol}"
      end
    end

    def self.prefix_selectors(prefix, selectors)
      selectors_to_prefix = selectors
      defines = []

      property_setters = selectors.select { |selector| selector[/\Aset[A-Z]/] }
      property_setters.each do |property_setter|
        property_getter = selectors.find do |selector|
          upper_getter = property_setter[3..-1]
          lower_getter = upper_getter[0, 1].downcase + upper_getter[1..-1]
          selector == upper_getter || selector == lower_getter
        end
        next if property_getter.nil?

        selectors_to_prefix.reject! { |selector| selector == property_setter }
        selectors_to_prefix.reject! { |selector| selector == property_getter }

        defines << "#{property_setter}=set#{prefix}#{property_getter}"
        defines << "#{property_getter}=#{prefix}#{property_getter}"
      end

      defines += prefix_symbols(prefix, selectors_to_prefix)
      defines
    end

    def self.run_nm(binaries, flags)
      `nm #{flags} #{binaries.join(' ')}`.split("\n")
    end
  end
end
