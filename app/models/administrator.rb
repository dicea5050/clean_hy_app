class Administrator < ApplicationRecord
  has_secure_password

  enum :role, { viewer: 0, editor: 1, admin: 2 }

  validates :email, presence: true, uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, presence: true

  def role_name
    case role
    when "admin"
      "管理者"
    when "editor"
      "編集者"
    when "viewer"
      "閲覧者"
    else
      "不明"
    end
  end
end
