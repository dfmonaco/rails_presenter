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

    context 'used for a relation' do
      class Foo; end
      class FooPresenter < RailsPresenter::Base; end

      let(:relation) { [Foo.new, Foo.new, Foo.new] }
      let(:presented_relation) { helper.present(relation) }

      before do
        relation.stub(:class) { ActiveRecord::Relation::ActiveRecord_Relation_Foo }
      end

      specify { presented_relation.all? {|p| p.is_a?(FooPresenter)}.should be_true }
    end

  end

  describe 'present a collection' do
    context 'used from a view' do
      it 'yields a new presenter object per presented object' do
        helper.present([Project.new, Project.new]) do |presenter|
          presenter.should be_a ProjectPresenter
        end
      end

      it 'yields the correct amount of presenters' do
        helper.present([Project.new, Project.new]).count.should == 2
      end

      it 'returns the original object when there is no presenter class' do
        class DummyClass; end

        dummy1 = DummyClass.new
        dummy2 = DummyClass.new
        dummy_collection = [dummy1, dummy2]

        helper.present(dummy_collection)[0].should == dummy1
        helper.present(dummy_collection)[1].should == dummy2
      end

      it 'returns the correct object' do
        dummy       = DummyClass.new
        presentable = Project.new
        collection  = [dummy, presentable]

        helper.present(collection)[0].should == dummy
        helper.present(collection)[1].should be_a ProjectPresenter
      end
    end

    context "presenting properly" do
      class Presentable
        def foo
          123
        end
      end
      class PresentablePresenter < RailsPresenter::Base
        def foo
          h.number_to_currency(super)
        end
      end
      class NonPresentable
        def foo
          123
        end
      end

      it "presents each object properly" do
        presentable     = Presentable.new
        non_presentable = NonPresentable.new
        collection = [
                      presentable,
                       non_presentable,
                       presentable,
                       non_presentable
                     ]

        output = []
        helper.present(collection) do |presenter|
          output << presenter.foo
        end

        output.should == ["$123,00", 123, "$123,00", 123]
      end
    end

  end
end
