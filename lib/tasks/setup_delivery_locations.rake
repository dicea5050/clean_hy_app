namespace :customers do
  desc "既存の顧客に本社納品先を追加"
  task setup_main_offices: :environment do
    count = 0
    Customer.find_each do |customer|
      next if customer.delivery_locations.exists?(is_main_office: true)

      delivery_location = customer.delivery_locations.create(
        name: "#{customer.company_name}（基本）",
        postal_code: customer.postal_code,
        address: customer.address,
        phone: customer.phone_number,
        contact_person: customer.contact_name,
        is_main_office: true
      )

      if delivery_location.persisted?
        count += 1
        puts "#{customer.company_name}の本社納品先を作成しました"
      else
        puts "【エラー】#{customer.company_name}の本社納品先作成に失敗: #{delivery_location.errors.full_messages.join(', ')}"
      end
    end

    puts "完了！#{count}件の本社納品先を作成しました。"
  end
end
