module Capybara
  class Query
    attr_accessor :selector, :locator, :options, :xpaths

    def initialize(*args)
      @options = if args.last.is_a?(Hash) then args.pop.dup else {} end
      if text = options[:text]
        @options[:text] = Regexp.escape(text) unless text.kind_of?(Regexp)
      end
      unless options.has_key?(:visible)
        @options[:visible] = Capybara.ignore_hidden_elements
      end

      if args[1]
        @selector = Selector.all[args[0]]
        @locator = args[1]
      else
        @selector = Selector.all.values.find { |s| s.match?(args[0]) }
        @locator = args[0]
      end
      @selector ||= Selector.all[Capybara.default_selector]

      xpath = @selector.call(@locator)
      if xpath.respond_to?(:to_xpaths)
        @xpaths = xpath.to_xpaths
      else
        @xpaths = [xpath.to_s].flatten
      end
    end

    def failure_message(node)
      message = selector.failure_message.call(node, self) if selector.failure_message
      message ||= options[:message]
      message ||= "Unable to find #{name} #{locator.inspect}"
      message
    end

    def name; selector.name; end

    def matches_filters?(node)
      return false if options[:text]      and not node.text.match(options[:text])
      return false if options[:visible]   and not node.visible?
      selector.custom_filters.each do |name, block|
        return false if options.has_key?(name) and not block.call(node, options[name])
      end
      true
    end
  end
end
