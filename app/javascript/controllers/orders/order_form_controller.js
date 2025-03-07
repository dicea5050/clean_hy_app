import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log('Orders controller connected')
    this.setupOrderForm()
  }

  setupOrderForm() {
    // 既存データの表示を初期化
    this.initializeExistingItems()
    
    // 商品選択時の処理
    this.setupProductSelects()
    
    // 数量選択時の処理
    this.setupQuantitySelects()
    
    // 商品追加ボタンの処理
    this.setupAddItemButton()
    
    // 削除ボタンの処理
    this.setupRemoveButtons()
    
    // 初期計算
    document.querySelectorAll('#order-items tbody tr:not(.empty-row)').forEach(row => {
      this.calculateSubtotal(row)
    })
    
    // 合計金額の更新
    this.updateOrderTotal()

    // フォーム送信時の処理追加
    this.setupFormSubmission()
  }

  // 以下、既存のメソッドをクラスメソッドとして移植
  // setupFormSubmission, initializeExistingItems, setupProductSelects,
  // setupQuantitySelects, calculateSubtotal, updateOrderTotal,
  // setupAddItemButton, setupRemoveButtons, configureUnitPriceField などを
  // このクラスのメソッドとして実装
  // ...
} 