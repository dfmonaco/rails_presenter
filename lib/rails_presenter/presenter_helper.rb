module RailsPresenter
  module PresenterHelper
    def present(object, template = self, &block)
      if [Array, ActiveRecord::Relation].include? object.class
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
