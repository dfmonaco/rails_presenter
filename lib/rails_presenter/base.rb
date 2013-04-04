require 'delegate'

module RailsPresenter
  class Base < SimpleDelegator
    include RailsPresenter::PresenterHelper

    @@nil_formatter = '----'

    class << self
      def location(*args)
        define_method(:self_location, ->(location=nil) do
          location ||= args.map do |p|
            p = p.to_s
            if p.delete! "@"
              public_send("get_#{p}")
            else
              p
            end
          end

          super(location)
        end)
      end

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


      def format(*attrs)
        formatter = attrs.pop.values.first

        module_name = formatter.to_s.camelize

        unless const_defined? module_name
          include const_set(module_name, Module.new)
        end

        formatter_module = const_get(module_name)

        formatter_module.module_eval do
          attrs.each do |attr|
            define_method(attr) do
              h.public_send(formatter, super())
            end
          end
        end
      end

      def inherited(child_class)
        child_class.instance_eval do
          format_blank_attributes(*possible_blank_attributes) if based_on_active_record?
        end
      end

      def format_blank_attributes(*attrs)
        attr_module = Module.new do
          attrs.each do |attr|
            define_method(attr) do
              return nil_formatter if super().blank?
              super()
            end
          end
        end

        include const_set("BlankAttributes", attr_module)
      end

      private

      def base_class
        @base_class ||= to_s.chomp('Presenter').constantize
      end

      def based_on_active_record?
        base_class.ancestors.include?(ActiveRecord::Base)
      end

      def possible_blank_attributes
        base_class.column_names.reject do |attr|
          ['id', 'created_at', 'updated_at'].include?(attr) ||
          /_id\z/.match(attr) ||
          base_class.validators_on(attr).any? {|v| !(v.options[:allow_nil] || v.options[:allow_blank])}
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

    def to_s
      respond_to?(:name) ? name : super
    end

    def with_attrs(*attrs)
      attrs_hash = attrs.reduce({}) do |hash, attr|
        if attr.is_a? Array
          hash[attr.first]= attr.last.call(self)
        else
          hash[attr]= public_send(attr)
        end
        hash
      end

      h.render partial: 'shared/show_with_attrs', locals: {attrs_hash: attrs_hash}
    end

    def self_location(location = target)
      h.polymorphic_path location
    end

    def link_to_self(options={})
      text = options[:text] || self.to_s
      path = options[:path] || self_location
      h.link_to text, path
    end

    def nil_formatter
      @@nil_formatter
    end

    def method_missing(method_name, *args)
      case method_name.to_s
      when /^h_(.*)$/
        get_iv_from_view($1)
      when /^get_(.*)$/
        return target if target.is_a? $1.camelize.constantize
        get_iv_from_view($1) || target.public_send($1)
      else
        super
      end
    end

    private
    def base_object_name
      target.class.to_s.underscore
    end

    def get_iv_from_view(iv_name)
      h.instance_variable_get("@#{iv_name}")
    end

  end
end
