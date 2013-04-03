# Rails Presenter

[![Build Status](https://travis-ci.org/dfmonaco/rails_presenter.png?branch=master)](https://travis-ci.org/dfmonaco/rails_presenter)

##Before:

```haml
# app/views/purchase_orders/show.html.haml

%h1 Purchase Order

%div
  %p
    %strong Date:
    %span= l(@order.date, format: :long)
  %p
    %strong Number:
    %span= @order.number
  %p
    %strong Customer:
    %span= @order.customer.name

  %table
    %thead
      %tr
        %th N°
        %th Quantity
        %th Unit
        %th Item
        %th Unit Price
        %th Discount
        %th Amount

    %tbody
      - @order.items.includes(:unit).each_with_index do |item, index|
        %tr
          %td= index + 1
          %td= number_with_precision(item.quantity)
          %td= item.unit.name
          %td= item.description
          %td= number_to_currency(item.unit_price)
          %td= number_to_percentage(item.discount)
          %td= number_to_currency(item.amount)

      %tr
        %td= number_to_currency(@order.subtotal)
        %td= number_to_currency(@order.vat)
        %td= number_to_currency(@order.total)
```

##After:

```haml
# app/views/purchase_orders/show.html.haml

%h1 Purchase Order

- present(@order) do |order_presenter|
  = order_presenter.with_attrs :date, :number, :customer

  %table
    %thead
      %tr
        %th N°
        %th Quantity
        %th Unit
        %th Item
        %th Unit Price
        %th Discount
        %th Amount

    %tbody
      - order_presenter.items.each_with_index do |item_presenter, index|
        %tr
          %td= index + 1
          %td= item_presenter.quantity
          %td= item_presenter.unit
          %td= item_presenter.description
          %td= item_presenter.unit_price
          %td= item_presenter.discount
          %td= item_presenter.amount

      %tr
        %td= order_presenter.subtotal
        %td= order_presenter.vat
        %td= order_presenter.total
```
