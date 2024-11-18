class Admin::AuthorizationPolicy
  attr_reader :account, :function_access_code

  def initialize(account, _record)
    @account = account[:account]
    @function_access_code = account[:function_access_code]
  end

  def index?
    return true if account&.default

    return false unless account && function_access && account_role && role_function_access && role_function_access.allow_read
    true
  end

  def read?
    return true if account && account.default
    
    return false unless account && function_access && role_function_access && role_function_access.allow_read
    true
  end

  def create?
    return true if account && account.default

    return false unless account && function_access && role_function_access && role_function_access.allow_create
    true
  end

  def update?
    return true if account && account.default

    return false unless account && function_access && role_function_access && role_function_access.allow_update
    true
  end

  def destroy?
    return true if account && account.default

    return false unless account && function_access && role_function_access && role_function_access.allow_delete
    true
  end

  def confirm?
    return true if account && account.default

    return false unless account && function_access && role_function_access && role_function_access.allow_confirm
    true
  end

  def cancel_confirm?
    return true if account && account.default

    return false unless function_access && role_function_access && role_function_access.allow_cancel_confirm
    true
  end

  def allow_import?
    false
  end

  private
    

    def function_access
      # @function_access ||= nil
      # @function_access ||= FunctionAccess.find_by(code: function_access_code, active: true)
      # if @function_access.blank?
      #   Rails.logger.warn("Function Access Code #{function_access_code} is not active or not found")
      #   false
      # end
      

      # @function_access
      @function_access ||= begin
        access = FunctionAccess.find_by(code: function_access_code, active: true)
        Rails.logger.warn("Function Access Code #{function_access_code} is not active or not found") if access.blank?
        access
      end
    end

    def account_role
      if account.blank?
        Rails.logger.warn("Accoun is not found")
        return false
      end

      if account.active == false
        Rails.logger.warn("Accoun is not active")
        return false
      end

      if account.role.blank?
        Rails.logger.warn("Account has no role")
        return false
      end

      if account.role.active == false
        Rails.logger.warn("Role is not active")
        return false
      end
      
      true
    end

    def role_function_access
      # @role_function_access ||= nil
      # @role_function_access ||= account.role.role_function_accesses.find_by(function_access: function_access)
      # if role_function_access.blank?
      #   Rails.logger.debug "role function access for account #{account.username} is not found"
      #   false
      # end

      # role_function_access
      @role_function_access ||= begin
        access = account.role.role_function_accesses.find_by(function_access: function_access)
        Rails.logger.debug "Role function access for account #{account.username} is not found" if access.blank?
        access
      end
    end

    # Kode ini tidak digunakan
    # karena cek otoriasasi berdasarkan role, bukan per account
    # def account_function_access
    #   if function_access
    #     Rails.logger.debug "account_function_access invoked"
    #     account_fa = account.account_function_accesses.joins(:function_access).find_by(function_access: function_access)
    #     if account_fa.present? && account_fa.active
    #       Rails.logger.info("Account Function Access for account ID: #{account.id} is found")
    #       account_fa
    #     else
    #       Rails.logger.info("
    #         Account Function Access for account: #{account.id},
    #         residential code: #{residential.code},
    #         function access: #{function_access_code}} is not found or inactive"
    #       )
    #       false
    #     end
    #   else
    #     false
    #   end
    # end

end