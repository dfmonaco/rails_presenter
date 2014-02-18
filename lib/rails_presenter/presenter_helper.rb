module RailsPresenter
  module PresenterHelper
    def present(object, template = self, &block)
      if object.is_a?(Array) || object.is_a?(ActiveRecord::Relation)
        if block
          return(present_collection(object, &block))
        else
          return object.map {|e| present(e)}
        end

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

    private
    def present_collection(collection)
      collection.each do |object|
        yield present(object)
      end
    end
  end
end
