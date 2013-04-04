# Rails Presenter

### Code Status
* [![Build Status](https://travis-ci.org/dfmonaco/rails_presenter.png?branch=master)](https://travis-ci.org/dfmonaco/rails_presenter)
* [![Coverage Status](https://coveralls.io/repos/dfmonaco/rails_presenter/badge.png?branch=master)](https://coveralls.io/r/dfmonaco/rails_presenter)

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
Basically there are two main components, the presenter class and the #present helper method.

### The presenter class
You can think of a presenter as a mix between a domain model object and a view template, every method call not defined in the current class will be forwarded to the original domain model object, besides you can access all the view template functionality through the #h method. Also the #target method will get you the unmodified original domain model object.

```ruby
class ProductPresenter < RailsPresenter::Base

  def image
    h.link_to(h.image_tag(super), h.product_path(target))
  end

end
```

### The #present helper method
The helper method #present it's used to instantiate new presenter objects, it takes any object, an array of objects or an ActiveRecord::Relation and returns the corresponding presenter instances.

```ruby
present(Customer.new).map(&:class) # => CustomerPresenter
present([Customer.new, Product.new]).map(&:class) # => [CustomerPresenter, ProductPresenter]
present(Product.limit(2).order(:name))).map(&:class) # => [ProductPresenter, ProductPresenter]
```
This method determines the name of the presenter class from the target object, for example a Project object would instantiate a ProjectPresenter object. If the assumed presenter class doesn't exist it will return the unmodified target object.

You can pass an optional block too:

```ruby
present(@purchase_order) do |purhase_order_presenter|
  purchase_order_presenter.date
  purchase_order_presenter.number
end
```
