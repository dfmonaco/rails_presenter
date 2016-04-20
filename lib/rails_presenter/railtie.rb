module RailsPresenter
  class Railtie < ::Rails::Railtie
    initializer "rails_presenter.configure_view" do |app|
      ActiveSupport.on_load :action_view do
        include PresenterHelper
      end
    end
  end
end
