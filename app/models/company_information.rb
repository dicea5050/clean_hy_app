class CompanyInformation < ApplicationRecord
  validates :name, presence: true
  validates :postal_code, presence: true
  validates :address, presence: true
  validates :phone_number, presence: true
  validates :invoice_registration_number, presence: true,
            format: { with: /\AT\d{13}\z/, message: "は「T」で始まる13桁の数字が必要です" }

  # 社印画像の追加
  has_one_attached :company_seal

  # 必要に応じて画像のバリデーションを追加
  validate :company_seal_format

  # 受注が存在する場合は自社情報を削除不可にする（業務上の参照を想定）
  before_destroy :prevent_destroy_if_orders_exist

  private

  def company_seal_format
    return unless company_seal.attached?

    unless company_seal.content_type.in?(%w[image/jpeg image/png image/gif])
      errors.add(:company_seal, "はJPEG、PNG、GIF形式でアップロードしてください")
    end

    # 必要に応じてサイズ制限も追加可能
    if company_seal.blob.byte_size > 5.megabytes
      errors.add(:company_seal, "は5MB以下のファイルを選択してください")
    end
  end

  def prevent_destroy_if_orders_exist
    if Order.exists?
      errors.add(:base, "受注情報が存在するため自社情報を削除できません。受注がない状態で削除してください。")
      throw(:abort)
    end
  end
end
