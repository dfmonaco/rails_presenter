require 'spec_helper'

describe RailsPresenter::PresenterHelper do
  describe '#present' do
    context 'used from a view' do
      it 'instantiates a new presenter object' do
        helper.present(Project.new).should be_a ProjectPresenter
      end

      it 'yields the presenter to the block' do
        helper.present(Project.new) do |presenter|
          presenter.should be_a ProjectPresenter
        end
      end

      it 'returns the original object when there is no presenter class' do
        class DummyClass; end

        dummy = DummyClass.new

        helper.present(dummy).should == dummy
      end
    end
  end

  context 'used from a presenter' do
    it 'works when called from a presenter context' do
      class Foo
        def to_s
          1234
        end
      end

      class FooPresenter < RailsPresenter::Base
        def to_s
          h.number_to_currency(super)
        end
      end

      class Bar
        def foo
          Foo.new
        end
      end


      class BarPresenter < RailsPresenter::Base
        def foo
          present(super).to_s
        end
      end

      presenter = BarPresenter.new(Bar.new, helper)

      presenter.foo.should == '$1.234,00'
    end
  end

  context 'used for a collection' do
    class Foo; end
    class FooPresenter < RailsPresenter::Base; end

    let(:collection) { [Foo.new, Foo.new, Foo.new] }
    let(:presented_collection) { helper.present(collection) }

    specify { presented_collection.all? {|p| p.is_a?(FooPresenter)}.should be_true }
  end
end
