module Downcaseable
  extend ActiveSupport::Concern

  included do
    before_save :downcase_attributes
  end

  class_methods do
    def downcase_fields(*fields)
      @downcase_fields = fields
    end

    def get_downcase_fields
      @downcase_fields || []
    end
  end

  private
    def downcase_attributes
      self.class.get_downcase_fields.each do |field|
        self[field] = self[field].downcase if self[field].present?
      end
    end
end