module PresenterExampleGroup
  extend ActiveSupport::Concern
  include ActionView::TestCase::Behavior

  def html_node(string, selector)
    Capybara.string(string).find(selector)
  end

  RSpec.configure do |config|
    config.include self,
      type: :presenter,
      example_group: { file_path: %r(spec/presenters) }
  end
end
