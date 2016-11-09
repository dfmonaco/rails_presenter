module RailsPresenter
  module PresenterHelper
    def present(template = self, object, with: nil, &block)
      return unless object

      if object.is_a?(Array) || object.is_a?(ActiveRecord::Relation)
        return object.map {|e| present(e, with: with)}
      end

      begin
        presenter_class = with || "#{object.class}Presenter".constantize
      rescue NameError
        presenter = object
      end

      presenter ||= presenter_class.new(object, template)

      block.call(presenter) if block
      presenter
    end
  end
end

