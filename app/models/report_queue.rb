class ReportQueue < ApplicationRecord
  belongs_to :generated_by, class_name: "Account", foreign_key: "generated_by_id"

  validates :name, presence: true, length: { maximum: 100 }
  validates :file_path, presence: true

end
