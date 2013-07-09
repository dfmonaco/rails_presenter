module RailsPresenter
  module PresenterHelper
    def present(object, template = self, &block)
      if object.is_a?(Array) || object.is_a?(ActiveRecord::Relation)
        return object.map {|e| present(e)}
      end

      begin
        presenter_class = "#{object.class}Presenter".constantize
      rescue NameError
        return object
      end

      presenter = presenter_class.new(object, template)

      block.call(presenter) if block
      presenter
    end
  end
end
