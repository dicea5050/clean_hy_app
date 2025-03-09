import { Controller } from "@hotwired/stimulus"

// 注文フォームのコントローラ
export default class extends Controller {
  connect() {
    console.log("Order form controller connected")
    this.setupCustomerSelect()
    this.setupOrderItemEvents()
    this.updateTotals()
  }

  setupCustomerSelect() {
    const customerSelect = document.getElementById('order_customer_id')
    if (customerSelect) {
      customerSelect.addEventListener('change', this.onCustomerChange.bind(this))
    }
  }

  onCustomerChange(event) {
    const customerId = event.target.value
    if (!customerId) return

    // 納品先選択フィールドを更新
    fetch(`/customers/${customerId}/delivery_locations`)
      .then(response => response.json())
      .then(data => {
        this.updateDeliveryLocationSelect(data)
      })
      .catch(error => console.error('Error fetching delivery locations:', error))
  }

  updateDeliveryLocationSelect(deliveryLocations) {
    const deliveryLocationSelect = document.getElementById('order_delivery_location_id')
    const container = deliveryLocationSelect.parentElement

    // 既存のセレクトを削除
    if (deliveryLocationSelect) {
      container.removeChild(deliveryLocationSelect)
    }

    // 新しいセレクトを作成
    const newSelect = document.createElement('select')
    newSelect.id = 'order_delivery_location_id'
    newSelect.name = 'order[delivery_location_id]'
    newSelect.className = 'form-control'
    newSelect.required = true

    // 空のオプションを追加
    const blankOption = document.createElement('option')
    blankOption.value = ''
    blankOption.text = '納品先を選択してください'
    newSelect.appendChild(blankOption)

    // 納品先オプションを追加
    deliveryLocations.forEach(location => {
      const option = document.createElement('option')
      option.value = location.id
      option.text = location.name
      newSelect.appendChild(option)
    })

    // コンテナに新しいセレクトを追加
    container.appendChild(newSelect)
  }

  // 以下は既存の注文アイテム関連の機能を想定しています
  setupOrderItemEvents() {
    // 省略 - 既存の実装があればそのまま残す
  }

  updateTotals() {
    // 省略 - 既存の実装があればそのまま残す
  }
}