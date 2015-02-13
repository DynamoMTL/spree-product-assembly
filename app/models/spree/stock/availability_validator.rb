module Spree
  module Stock
    # Overridden from spree core to make it also check for assembly parts stock
    class AvailabilityValidator < ActiveModel::Validator
      def validate(line_item)
        unit_count = line_item.inventory_units.size  
        return if unit_count >= line_item.quantity
        
        product = line_item.product

        valid = if product.assembly?
          line_item.parts.all? do |part|
            Stock::Quantifier.new(part).can_supply?(line_item.count_of(part) * (line_item.quantity - unit_count))
          end
        else
          Stock::Quantifier.new(line_item.variant).can_supply?(line_item.quantity - unit_count)
        end

        unless valid
          variant = line_item.variant
          display_name = %Q{#{variant.name}}
          display_name += %Q{ (#{variant.options_text})} unless variant.options_text.blank?

          line_item.errors[:quantity] << Spree.t(:out_of_stock, :scope => :order_populator, :item => display_name.inspect)
        end
      end
    end
  end
end
