class InvoiceOrder < ApplicationRecord
  belongs_to :invoice
  belongs_to :order
end 