module ApplicationHelper
  include Pagy::Frontend

  def human_readable_size(file_path)
    if File.exist?(file_path)
      file_size_in_bytes = File.size(file_path)
      (file_size_in_bytes.to_f / 1_048_576).round(2)
    else
      0
    end
  end

  def can_read?(function_access_code)
    Pundit
      .policy(
        pundit_context(function_access_code),
        [ :admin, :authorization ]).read?
  end

  def can_update?(function_access_code)
    Pundit
      .policy(
        pundit_context(function_access_code),
        [ :admin, :authorization ]).update?
  end

  def can_destroy?(function_access_code)
    Pundit
      .policy(
        pundit_context(function_access_code),
        [ :admin, :authorization ]).destroy?
  end

  private
    def pundit_context(function_access_code)
      {
          account: Current.account,
          function_access_code: function_access_code
      }
    end
end
