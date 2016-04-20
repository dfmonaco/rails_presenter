# RailsPresenter

RailsPresenter will help you to clean up your views and avoid helpers hell.

## How does it work?
Basically there are two main components, the `presenter object` and the `#present` helper method.

### The presenter object
You can think of a presenter as a mix between a domain model object and a view template, every method call not defined in the current class will be forwarded to the original domain model object, besides you can access all the view template functionality through the `#h` method. Also the `#target` (also aliased as `#object`) method will get you the unmodified original domain model object.

```ruby
class ProductPresenter < RailsPresenter::Base

  def image
    h.link_to(h.image_tag(super), h.product_path(target))
  end

end
```

### The #present helper method
The helper method `#present` it's used to instantiate new presenter objects, it takes any object, an array of objects or an ActiveRecord::Relation and returns the corresponding presenter instances.

```ruby
present(Customer.new).map(&:class) # => CustomerPresenter
present([Customer.new, Product.new]).map(&:class) # => [CustomerPresenter, ProductPresenter]
present(Product.limit(2).order(:name))).map(&:class) # => [ProductPresenter, ProductPresenter]
```
This method determines the name of the presenter class from the target object, for example a Project object would instantiate a ProjectPresenter object. If the assumed presenter class doesn't exist it will return the unmodified target object.

You can pass an optional block too, in fact this the intended usage of the helper in your views:

```ruby
present(@purchase_order) do |purchase_order_presenter|
  purchase_order_presenter.date
  purchase_order_presenter.number
end
```

## Features
### Present associations

Define the associated objects that you want to get automatically presented.

```ruby
class Post
  has_many :comments
  belongs_to :user
end

class PostPresenter < RailsPresenter::Base
  present :comments, :user
end

post_presenter = present(Post.last)

post_presenter.comments.first.class # => CommentPresenter
post_presenter.user.class # => UserPresenter
```
### Use `super` at will

You can very easily add functionality on top of what RailsPresenter already provides, you just have to redefine your method and call `super`, class inheritance, module mixin, everything works as expected, as RailsPresenter uses a set of well identified (not anonymous) modules to extend functionality.

```ruby
class SupplierPresenter < CompanyPresenter; end
class CompanyPresenter < RailsPresenter::Base; end

SupplierPresenter.ancestors

# =>

#      [SupplierPresenter,
#       SupplierPresenter::NumberToCurrency,
#       SupplierPresenter::SupplierPresenterAssociations,
#       SupplierPresenter::BlankAttributes,
#       CompanyPresenter,
#       CompanyPresenter::BlankAttributes,
#       RailsPresenter::Base,
#       etc, etc...]
```

## Are you crazy? We already have Draper!!

Well yes, Draper it's an amazing library and it inspired RailsPresenter in many ways (and was developed by people way more smarter than me), so I will try to illustrate what motivated me to reinvent the wheel.

At a basic level both provide the same functionality, but for my personal needs I find Draper too complex and with too many options, I prefer a simpler interface and good conventions, besides RailsPresenter implements a set of presentation related functionality on top of basic delegation as you can see on the aforementioned features. Additionally RailsPresenter it's meant to be used only inside the views, through the `#present` helper, so it doesn't provides any controller related functionality.

On the other side Draper has a much more fine-grained control over the methods delegated to the target object, RailsPresenter just will delegate every method called not defined in the presenter.

### Examples:

#### Decorating a single object

```ruby
# Draper way

Article.first.decorate
ArticleDecorator.new(Article.first)
ArticleDecorator.decorate(Article.first)

# RailsPresenter way

present(Article.first)
```
#### Decorating a collection

```ruby
# Draper way

ArticleDecorator.decorate_collection(Article.all)
Article.popular.decorate # this only works for an ActiveRecord relation
[Article.first, Comment.last, User.find(3)].decorate # you can't do this

# RailsPresenter way

present(Article.all)
present(Article.popular)
present([Article.first, Comment.last, User.find(3)]) # you can decorate arbitrary arrays
```
#### Decorating associations

```ruby
# Draper way

class Article < ActiveRecord::Base
  # I think the following scope it's completely view related and doesn't belongs here
  def self.comments_with_author_included_and_ordered_by_created_at
    comments.includes(:author).order('comments.created_at')
  end
end

class ArticleDecorator < Draper::Decorator
  decorates_association :comments, scope: :comments_with_author_included_and_ordered_by_created_at
end

# RailsPresenter way

class ArticlePresenter < RailsPresenter::Base
  present :comments do
    includes(:author).order('comments.created_at')
  end
end
```

## Inspiration

* Railscast: http://railscasts.com/episodes/287-presenters-from-scratch
* Book: http://pragprog.com/book/warv/the-rails-view
* Gem: https://github.com/drapergem/draper

## Installation

Add this line to your application's Gemfile:

    gem 'rails_presenter'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rails_presenter

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

__MIT License__. *Copyright 2013 Diego Mónaco*
















