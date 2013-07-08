require 'spec_helper'
class Project < ActiveRecord::Base
  def self.create_column(name, default = nil, type = 'string')
    ActiveRecord::ConnectionAdapters::Column.new(name, default, type)
  end
  def self.columns
    [create_column('name'),
      create_column('project_manager'),
      create_column('id'),
      create_column('created_at'),
      create_column('updated_at'),
      create_column('something_id')]
  end
  attr_accessor :company

  def persisted?
    true
  end
end

class Company < ActiveRecord::Base
  def self.create_column(name, default = nil, type = 'string')
    ActiveRecord::ConnectionAdapters::Column.new(name, default, type)
  end
  def self.columns
    [create_column('name'),
      create_column('id'),
      create_column('created_at'),
      create_column('updated_at'),
      create_column('something_id')]
  end
end

class Contract < ActiveRecord::Base
  def self.create_column(name, default = nil, type = 'string')
    ActiveRecord::ConnectionAdapters::Column.new(name, default, type)
  end
  def self.columns
    [create_column('foo'),
      create_column('id'),
      create_column('created_at'),
      create_column('updated_at'),
      create_column('something_id')]
  end
  attr_accessor :project

  def persisted?
    true
  end
end

class User < ActiveRecord::Base
  def self.create_column(name, default = nil, type = 'string')
    ActiveRecord::ConnectionAdapters::Column.new(name, default, type)
  end
  def self.columns
    [create_column('foo'),
      create_column('id'),
      create_column('created_at'),
      create_column('updated_at'),
      create_column('something_id')]
  end
  attr_accessor :project

  def persisted?
    true
  end
end

class DummyRecord < ActiveRecord::Base
  def self.create_column(name, default = nil, type = 'string')
    ActiveRecord::ConnectionAdapters::Column.new(name, default, type)
  end

  def self.columns
    [create_column('foo'),
      create_column('bar'),
      create_column('baz'),
      create_column('qux'),
      create_column('id'),
      create_column('created_at'),
      create_column('updated_at'),
      create_column('something_id')]
  end

  validates :foo, presence: true
  validates :bar, numericality: true, allow_nil: true
  validates :baz, numericality: true, allow_blank: true
end

describe RailsPresenter::Base do
  context 'presented object is an active record' do

    let!(:child_class) do
      class DummyRecordPresenter < RailsPresenter::Base
        self
      end
    end

    specify { child_class.ancestors.should include(DummyRecordPresenter::BlankAttributes) }

    specify { DummyRecordPresenter::BlankAttributes.instance_methods.should == [:bar, :baz, :qux] }

    specify { child_class.new(DummyRecord.new, double).bar.should == '----' }

    specify { child_class.new(DummyRecord.new, double).foo.should be_nil }
  end

  context 'presented object is not an active record' do
    specify do
      class ActiveFoo
      end

      class ActiveFooPresenter < RailsPresenter::Base
        self
      end

      ActiveFooPresenter.const_defined?('BlankAttributes').should_not be_true
    end
  end

  describe '.present' do
    class Bar; end
    class BarPresenter < RailsPresenter::Base; end

    class Qux; end
    class QuxPresenter < RailsPresenter::Base; end

    class Baz; end
    class BazPresenter < RailsPresenter::Base; end

    class Foo
      def bar
        Bar.new
      end

      def baz
        Baz.new
      end

      def qux
        Qux.new
      end

      def collection
        [bar, baz, qux]
      end

      def scopable_collection
        [bar, baz, qux].tap do |c|
          def c.scoped
            drop(1)
          end
        end
      end
    end

    let(:foo) { Foo.new }
    let(:foo_presenter) { FooPresenter.new(foo, view) }

    class FooPresenter < RailsPresenter::Base
      present :bar, :qux
      present :baz
      present :collection
      present :scopable_collection do
        drop(1)
      end
    end

    specify { foo_presenter.bar.should be_an_instance_of(BarPresenter) }
    specify { foo_presenter.qux.should be_an_instance_of(QuxPresenter) }
    specify { foo_presenter.baz.should be_an_instance_of(BazPresenter) }
    specify { foo_presenter.collection.map(&:class).should eq([BarPresenter, BazPresenter, QuxPresenter]) }
   # I have to test this twice, because the method is working for the first call but not for the subsequents
    specify do
      foo_presenter.scopable_collection.map(&:class).should eq([QuxPresenter])
      foo_presenter.scopable_collection.map(&:class).should eq([QuxPresenter])
    end
    specify { FooPresenter.ancestors.should include(FooPresenter::FooPresenterAssociations) }
    specify { FooPresenter::FooPresenterAssociations.instance_methods.should eq([:bar, :qux, :baz, :collection, :scopable_collection]) }
  end

  describe '.location' do
    class ContractPresenter < RailsPresenter::Base
      location :@project, :@contract
    end

    let(:project) { Project.new(id:2) }
    let(:contract) { Contract.new(id:5, project: project) }
    let(:contract_presenter) { ContractPresenter.new(contract, view) }

    specify { contract_presenter.self_location.should eq('/projects/2/contracts/5') }

    class UserPresenter < RailsPresenter::Base
      location :@project, :user
    end

    let(:user) { User.new(project: project) }
    let(:user_presenter) { UserPresenter.new(user, view) }

    specify { user_presenter.self_location.should eq('/projects/2/user') }
  end


  describe '.format' do
    class Foo
      def quantity
        3.45234
      end

      def other_quantity
        234.5667
      end

      def amount
        123.456
      end

      def vat_amount
        345.6789
      end
    end

    class FooPresenter < RailsPresenter::Base
      format :quantity, :other_quantity, with: :number_with_precision
      format :amount, with: :number_to_currency
      format :vat_amount, with: :number_to_currency
    end

    let(:foo) { Foo.new }
    let(:presenter) { FooPresenter.new(foo, view) }

    specify { presenter.quantity.should eq('3,45') }
    specify { presenter.other_quantity.should eq('234,57') }
    specify { presenter.amount.should eq('$123,46') }
    specify { presenter.vat_amount.should eq('$345,68') }
    specify { FooPresenter.ancestors.should include(FooPresenter::NumberToCurrency) }
    specify { FooPresenter.ancestors.should include(FooPresenter::NumberWithPrecision) }
  end


  describe 'general presenters methods' do
    class ProjectPresenter < RailsPresenter::Base; end
    let(:presenter) { ProjectPresenter.new(project, view) }
    let(:company) { Company.new(name: 'acme') }
    let(:project) { Project.new(id:58, name: 'foo', project_manager: 'bar', company: company) }

    describe '#with_attrs' do
      let(:html) { Capybara.string presenter.with_attrs(:name, :project_manager, [:company, ->(p) { p.company.name }]) }

      it 'creates a div#show-with-attrs' do
        html.should have_selector('div.show-with-attrs')
      end

      it 'renders each translated attribute name within a <p> inside a <strong>' do
        html.find('p:first strong').text.should == 'Name: '
        html.find('p:nth-of-type(2) strong').text.should == 'Project Manager: '
        html.find('p:last strong').text.should == 'Company: '
      end

      it 'renders each attribute value within a <p>' do
        html.find('p:first span').text.should == 'foo'
        html.find('p:nth-of-type(2) span').text.should == 'bar'
        html.find('p:last span').text.should == 'acme'
      end
    end

    describe '#link_to_self' do
      let(:html) { Capybara.string(presenter.link_to_self).find('a') }

      it 'renders a link to the project' do
        html[:href].should == "/projects/58"
        html.text.should == 'foo'
      end
    end

    describe '#get_* and #h_* courtesy of method_missing' do
      class Foo; end

      let(:foo) { Foo.new }

      context 'corresponding instance variable exists in the view' do
        before { view.instance_variable_set(:@foo, foo) }

        it 'gets the object from an instance variable in the view' do
          presenter.get_foo.should == foo
        end

        specify { presenter.h_foo.should == foo }
      end

      context 'corresponding instance variable doesnt exists in the view' do
        before { project.stub(:foo) { foo } }

        it 'gets the object from the base object' do
          presenter.get_foo.should == foo
        end

        specify { presenter.h_foo.should == nil }
      end

      context 'getting the base object' do
        specify { presenter.get_project.should eq(project) }
      end

      context 'getting the base object for a descendant' do
        class A; end
        class B < A; end
        class BPresenter < RailsPresenter::Base; end
        let(:b) { B.new }
        let(:b_presenter) { BPresenter.new(b, view) }

        specify { expect(b_presenter.get_a).to eq(b) }
        specify { expect(b_presenter.get_b).to eq(b) }
      end

    end

  end
end
