# RailsPresenter

[![Gem Version](https://badge.fury.io/rb/rails_presenter.png)](http://badge.fury.io/rb/rails_presenter)
[![Build Status](https://travis-ci.org/dfmonaco/rails_presenter.png?branch=master)](https://travis-ci.org/dfmonaco/rails_presenter)
[![Coverage Status](https://coveralls.io/repos/dfmonaco/rails_presenter/badge.png?branch=master)](https://coveralls.io/r/dfmonaco/rails_presenter)

RailsPresenter will help you to clean up your views and avoid helpers hell.

##Before:

```haml
# app/views/purchase_orders/show.html.haml

%h1 Purchase Order
%div
  %p
    %strong Date:
    %span= localize(@purchase_order.date, format: :long)
  %p
    %strong Number:
    %span= @purchase_order.number

%h2 Customer
%div
  %p
    %strong Name:
    %span= @purchase_order.customer.name
  %p
    %strong Phone:
    %span= @purchase_order.customer.phone || '------'
  %p
    %strong Email:
    %span= mail_to(@purchase_order.customer.email)

  %table
    %thead
      %tr
        %th N°
        %th Quantity
        %th Item
        %th Unit Price
        %th Discount
        %th Amount

    %tbody
      - @purchase_order.items.includes(:product).each_with_index do |item, index|
        %tr
          %td= index + 1
          %td= number_with_precision(item.quantity)
          %td= item.product.name
          %td= number_to_currency(item.unit_price)
          %td= number_to_percentage(item.discount)
          %td= number_to_currency(item.amount)

%div
  %p
    %strong Subtotal:
    %span= number_to_currency(@purchase_order.subtotal)
  %p
    %strong Vat:
    %span= number_to_currency(@purchase_order.vat)
  %p
    %strong Total:
    %span= number_to_currency(@purchase_order.total)

```

##After:

```haml
# app/views/purchase_orders/show.html.haml

- present(@purchase_order) do |order_presenter|

  %h1 Purchase Order
  = order_presenter.with_attrs :date, :number

  %h2 Customer
  = order_presenter.customer.with_attrs :name, :phone, :email

  %table
    %thead
      %tr
        %th N°
        %th Quantity
        %th Item
        %th Unit Price
        %th Discount
        %th Amount

    %tbody
      - order_presenter.items.each_with_index do |item_presenter, index|
        %tr
          %td= index + 1
          %td= item_presenter.quantity
          %td= item_presenter.product
          %td= item_presenter.unit_price
          %td= item_presenter.discount
          %td= item_presenter.amount

  = order_presenter.with_attrs :subtotal, :vat, :total
```

## How did we get here?

```ruby
# app/presenters/purchase_order_presenter.rb

class PurchaseOrderPresenter < RailsPresenter::Base
  present :customer

  present :items do
    includes(:product)
  end

  format :subtotal, :vat, :total, with: :number_to_currency

  def date
    h.localize(super, format: :long)
  end
end
```

```ruby
# app/presenters/customer_presenter.rb

class CustomerPresenter < RailsPresenter::Base
  def email
    h.mail_to super
  end
end
```

```ruby
# app/presenters/item_presenter.rb

class ItemPresenter < RailsPresenter::Base
  present :product

  format :quantity, with: :number_with_precision
  format :unit_price, :amount, with: :number_to_currency
  format :discount, with: :number_to_percentage
end
```

```ruby
# app/presenters/product_presenter.rb

class ProductPresenter < RailsPresenter::Base
end
```

## How does it work?
Basically there are two main components, the `presenter object` and the `#present` helper method.

### The presenter object
You can think of a presenter as a mix between a domain model object and a view template, every method call not defined in the current class will be forwarded to the original domain model object, besides you can access all the view template functionality through the `#h` method. Also the `#target` method will get you the unmodified original domain model object.

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

You can pass an optional block too:

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

### Format attributes with rails helpers

Configure in your presenter class how you want your attributes to be formatted for display.

```ruby
class InvoicePresenter < RailsPresenter::Base
  format :net_amount, :total_amount, with: :number_to_currency
  format :vat_percentage, with: :number_to_percentage
end

invoice_presenter = present(Invoice.last)

invoice_presenter.net_amount # => $234,56
invoice_presenter.vat_percentage # => 10,5%
```

### Nil Formatter

RailsPresenter will format any attribute with a nil value with a more descriptive string. (In future versions this string will be configurable)

```ruby
purchase_order.description # => nil

present(purchase_order).description # => '----'
```

### Show your object attributes in a consistent and DRY way

Use the default partial to show your object's attributes or write your own.

```ruby
user_presenter.with_attrs :first_name, :last_name, :email
```

This helper will render the following partial passing it a hash named `attrs_hash` that represents the names and values for the given attributes.

```erb
# shared/_show_with_attrs.html.erb

<div class="show-with-attrs">
  <% attrs_hash.each do |name, value| %>
    <p>
      <strong><%= "#{name.to_s.titleize}: " %></strong>
      <span><%= value %></span>
    </p>
  <% end %>
</div>
```

If you define your own partial with the same name inside the views/shared directory it will override the provided default.

### Teach your objects how to represent themselves

To take advantage of Rails calling `#to_s` before rendering an object inside a view template, RailsPresenter redefines this method to call a `#name` method if it is defined. (In future versions this will be configurable and you will be able to define an array of methods to try before using default `#to_s` behavior)
So if you have the right method defined, you can just drop your object in a view template and without calling any method it will represent itself.

```haml
# contacts/show.html.haml

= @contact # => "#<Contact:0xc1ad978>"

= @contact.name # => 'John Doe'

= present(@contact) # => 'John Doe'
```

### Automagic links

Set the location of your resources once and get free links everywhere.

```ruby
class CommentPresenter
  location :@post, :@comment
end

comment_presenter.link_to_self # => "<a href="/posts/32/comments/21">Comment Name</a>"
```

You can use it with namespaced resources or has_one relationships

```ruby
class ProfilePresenter
  location :dashboard, :@user, :profile

  def name
    "#{user.name}'s Profile"
  end
end

profile_presenter.link_to_self

# => "<a href="dashboard/users/12/profile">John Doe's Profile</a>"
```

By default RailsPresenter will call `#to_s` to get the text to be used inside the anchor, but you can pass a custom value too:

```ruby
profile_presenter.link_to_self text: 'View your Profile'

# => "<a href="dashboard/users/12/profile">View your Profile</a>"
```

To get the parent resources RailsPresenter will try to get an instance variable with the same name as the parent, and if can't find any it will try to get it from an accessor method in the target object. In the example above it would try first to get a `@user` instance variable and if can't find it, it will call `profile_presenter.target.user`.

## License

__MIT License__. *Copyright 2013 Diego Mónaco*















