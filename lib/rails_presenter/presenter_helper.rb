module RailsPresenter
  module PresenterHelper
    def present(object, custom_presenter = nil, template = self, &block)
      if object.is_a?(Array) || object.is_a?(ActiveRecord::Relation)
        if block
          return(present_collection(object, &block))
        else
          return object.map {|e| present(e)}
        end

      end

      begin
        object_class = if custom_presenter && custom_presenter.is_a?(Symbol)
                         custom_presenter.to_s.split("_").map(&:capitalize).join
                       else
                         object.class
                       end
        presenter_class = "#{object_class}Presenter".constantize
      rescue NameError
        return object
      end

      presenter = presenter_class.new(object, template)

      block.call(presenter) if block
      presenter
    end

    private
    def present_collection(collection)
      collection.each do |object|
        yield present(object)
      end
    end
  end
end
