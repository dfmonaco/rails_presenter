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

    def present_collection(collection, template = self, &block)
      if !collection.is_a?(Array) || !collection.is_a?(ActiveRecord::Relation) || !block_given?
        return present(collection)
      end

      collection.each do |object|
        begin
          presenter_class = "#{object.class}Presenter".constantize
        rescue NameError
          block.call(object)
        end

        presenter = presenter_class.new(object, template)

        block.call(presenter)
      end

    end
  end


  # def present_collection(object, template = self, &block)
  #   present(object, template = self).each do |collection_presenter|
  #     block.call(collection_presenter) if block_given?
  #   end
  # end
end
