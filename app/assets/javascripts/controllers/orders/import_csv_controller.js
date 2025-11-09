import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.form = this.element
    this.setupFormValidation()
  }

  setupFormValidation() {
    this.form.addEventListener('submit', (event) => {
      console.log('フォーム送信イベントが発生しました')

      const fileInput = document.getElementById('file')
      if (!fileInput || fileInput.files.length === 0) {
        event.preventDefault()
        alert('CSVファイルを選択してください')
        return false
      }

      console.log('選択されたファイル:', fileInput.files[0].name)
      return true
    })
  }
}