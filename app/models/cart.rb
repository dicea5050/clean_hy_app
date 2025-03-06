class Cart
  include ActiveModel::Model

  attr_reader :items

  def initialize
    @items = []
  end

  def add_item(product, quantity = 1)
    item = @items.find { |i| i.product_id == product.id }

    if item
      item.quantity += quantity
    else
      @items << CartItem.new(product, quantity)
    end
  end

  def total_price
    @items.sum { |item| item.subtotal }
  end

  def total_tax
    (total_price * 0.1).round
  end

  def total_with_tax
    total_price + total_tax
  end

  def serialize
    {
      "items" => @items.map(&:serialize)
    }
  end

  def self.from_hash(hash)
    cart = new

    if hash["items"]
      hash["items"].each do |item_hash|
        product = Product.find(item_hash["product_id"])
        cart.add_item(product, item_hash["quantity"].to_i)
      end
    end

    cart
  end
end

class CartItem
  attr_reader :product_id, :product
  attr_accessor :quantity

  def initialize(product, quantity = 1)
    @product = product
    @product_id = product.id
    @quantity = quantity
  end

  def subtotal
    @product.price * @quantity
  end

  def serialize
    {
      "product_id" => @product_id,
      "quantity" => @quantity
    }
  end
end
