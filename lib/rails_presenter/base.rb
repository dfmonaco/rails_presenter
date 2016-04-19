require 'delegate'

module RailsPresenter
  class Base < SimpleDelegator
    include RailsPresenter::PresenterHelper

    class << self

      def present(*args, &block)
        module_name = "#{name}Associations"

        unless const_defined? module_name
          include const_set(module_name, Module.new)
        end

        associations_module = const_get(module_name)

        block ||= proc { self }

        associations_module.module_eval do
          args.each do |assoc_name|
            define_method(assoc_name) do
              instance_variable_get("@#{assoc_name}") ||
              begin
                association = if super().is_a?(Array) && super().respond_to?(:scoped)
                  super().scoped
                else
                  super()
                end
                instance_variable_set("@#{assoc_name}", present(association.instance_eval(&block)))
              end
            end
          end
        end
      end

    end

    def initialize(base_object, template)
      @template = template
      super(base_object)
    end

    def present(object)
      super(object, h)
    end

    def h
      @template
    end

    def target
      __getobj__
    end

    alias_method :o, :target
    alias_method :object, :target
  end
end

