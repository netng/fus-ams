module Admin::Entries
  class CapitalProposalsController < ApplicationAdminController
    before_action :set_capital_proposal, only: [ :edit, :update, :destroy ]
    before_action :set_function_access_code

    def index
      authorize :authorization, :index?

      @q = CapitalProposal.ransack(params[:q])
      @q.sorts = [ "date desc" ] if @q.sorts.empty?
      scope = @q.result.includes(:capital_proposal_type, :capital_proposal_group, :site, :department)
      @pagy, @capital_proposals = pagy(scope)
    end

    def new
      authorize :authorization, :create?

      @capital_proposal = CapitalProposal.new
      @capital_proposal.date ||= Date.today.strftime("%Y-%m-%d")
    end

    def create
      authorize :authorization, :create?

      @capital_proposal = CapitalProposal.new(capital_proposal_params)
      @capital_proposal.date ||= Date.today.strftime("%Y-%m-%d")
      @capital_proposal.amount = @capital_proposal.equiv_amount * @capital_proposal.rate

      respond_to do |format|
        if @capital_proposal.save
          format.html { redirect_to admin_capital_proposals_path, notice: t("custom.flash.notices.successfully.created", model: t("activerecord.models.capital_proposal")) }
        else
          format.html { render :new, status: :unprocessable_entity }
        end
      end
    end

    def edit
      authorize :authorization, :update?
    end

    def update
      authorize :authorization, :update?

      respond_to do |format|
        if @capital_proposal.update(capital_proposal_params)
          format.html { redirect_to admin_capital_proposals_path, notice: t("custom.flash.notices.successfully.updated", model: t("activerecord.models.capital_proposal")) }
        else
          format.html { render :edit, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      authorize :authorization, :destroy?
    end

    def destroy_many
      authorize :authorization, :destroy?

      capital_proposal_ids = params[:capital_proposal_ids]

      ActiveRecord::Base.transaction do
        capital_proposals = CapitalProposal.where(id: capital_proposal_ids)

        capital_proposals.each do |capital_proposal|
          unless capital_proposal.destroy
            error_message = capital_proposal.errors.full_messages.join("")
            redirect_to admin_capital_proposals_path, alert: "#{error_message} - #{t('activerecord.models.capital_proposal')} id: #{capital_proposal.number}"
            raise ActiveRecord::Rollback
          end
        end

        respond_to do |format|
          format.html { redirect_to admin_capital_proposals_path, notice: t("custom.flash.notices.successfully.destroyed", model: t("activerecord.models.capital_proposal")) }
        end
      end
    end

    def import
      authorize :authorization, :create?
    end

    def process_import
      authorize :authorization, :create?
      allowed_extension = [ ".xlsx", ".csv" ]
      file = params[:file]
      data = []
      batch_size = 1000
      maybe_error = false

      start_time = Time.now

      created_by = Current.account.username
      request_id = Current.request_id
      user_agent = Current.user_agent
      ip_address = Current.ip_address

      if file.present?
        if !allowed_extension.include?(File.extname(file.original_filename))
          return redirect_back_or_to import_admin_capital_proposals_path, alert: t("custom.errors.invalid_allowed_extension")
        end

        xlsx = Roo::Spreadsheet.open(file.path)

        sheet = xlsx.sheet(0)

        capital_proposal_attributes_headers = {
          number: "Number",
          real_number: "Real number",
          capital_proposal_type: "Type",
          capital_proposal_group: "Group",
          currency: "Currency id",
          site: "Site id",
          department: "Department id",
          date: "Date",
          description: "Description",
          equiv_amount: "Equiv amount",
          rate: "Exchange rate",
          status: "Status",
          budget_ref_number: "Budget ref number",
          budget_amount: "Budget amount"
        }

        begin
          ActiveRecord::Base.transaction do
            sheet.parse(capital_proposal_attributes_headers).each do |row|
              capital_proposal_type = CapitalProposalType.find_by_id_capital_proposal_type(row[:capital_proposal_type])
              capital_proposal_group = CapitalProposalGroup.find_by_id_capital_proposal_group(row[:capital_proposal_group].upcase)
              site = Site.find_by_id_site(row[:site].strip.upcase)
              department = Department.find_by_id_department(row[:department])
              puts "DEPARTMENT ===>>  #{department}"
              currency = Currency.find_by_id_currency(row[:currency])

              if capital_proposal_type.nil?
                maybe_error = true
                redirect_back_or_to import_admin_capital_proposals_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.capital_proposal_type"), id: row[:capital_proposal_type])
                raise ActiveRecord::Rollback
                return
              end

              if capital_proposal_group.nil?
                maybe_error = true
                redirect_back_or_to import_admin_capital_proposals_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.capital_proposal_group"), id: row[:capital_proposal_group])
                raise ActiveRecord::Rollback
                return
              end

              if site.nil?
                # maybe_error = true
                logger.debug "request_id: #{request.request_id} - CP number: #{row[:number]} - reason: Site id `#{row[:site]}` is not found"
                  #
                  # redirect_back_or_to import_admin_capital_proposals_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.site"), id: row[:site])
                  # raise ActiveRecord::Rollback
                  # return

                  # safety net jika po tidak ada namun pada file import dari fus-online po number tertulis ynag sebenernya po tidak ada di db fusonline, mungkin terhapus
                  site = Site.create(
                    id_site: row[:site].strip.upcase,
                    name: "#{row[:site]} (safety net)",
                    site_stat: SiteStat.find_by_id_site_stat("safety-net"),
                    site_group: SiteGroup.find_by_id_site_group("safety-net"),

                  )
              end

              if department.nil?
                # maybe_error = true
                logger.debug "request_id: #{request.request_id} - CP number: #{row[:number]} - reason: Department id `#{row[:department]}` is not found"
                # redirect_back_or_to import_admin_capital_proposals_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.department"), id: row[:department])
                # raise ActiveRecord::Rollback
                # return
                # # safety net jika po tidak ada namun pada file import dari fus-online po number tertulis ynag sebenernya po tidak ada di db fusonline, mungkin terhapus
                department = Department.create(
                  name: "#{row[:department].strip.upcase} (safety net)",
                  id_department: row[:department].strip.upcase

                )
              end

              if currency.nil?
                maybe_error = true
                redirect_back_or_to import_admin_capital_proposals_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.currency"), id: row[:currency])
                raise ActiveRecord::Rollback
                return
              end

              data << {
                number: row[:number],
                real_number: row[:real_number],
                capital_proposal_type_id: capital_proposal_type.id,
                capital_proposal_group_id: capital_proposal_group.id,
                currency_id: currency.id,
                site_id: site.id,
                department_id: department.id,
                date: row[:date],
                description: row[:description],
                equiv_amount: row[:equiv_amount],
                rate: row[:rate],
                status: row[:status],
                budget_ref_number: row[:budget_ref_number],
                budget_amount: row[:budget_amount],
                amount: row[:equiv_amount].to_i * row[:rate].to_i,
                created_by: created_by,
                request_id: request_id,
                user_agent: user_agent,
                ip_address: ip_address
              }

              if data.size >= batch_size
                CapitalProposal.insert_all!(data)
                data.clear
              end
            end

            CapitalProposal.insert_all!(data) unless data.empty?
          end

        rescue Roo::HeaderRowNotFoundError => e
          return redirect_to import_admin_capital_proposals_path, alert: t("custom.errors.invalid_import_template", errors: e)


        # Penanganan untuk duplikat data
        rescue ActiveRecord::RecordNotUnique => e
          logger.error "#{Current.request_id} - Duplicate data: #{e.message}"
          duplicate_field = e.message.match(/Key \((.*?)\)=/)[1] rescue "data"
          duplicate_value = e.message.match(/\((.*?)\)=\((.*?)\)/)[2] rescue "unknown"
          humanized_message = t("custom.errors.duplicate_data", field: duplicate_field.humanize, value: duplicate_value)
          return redirect_back_or_to import_admin_capital_proposals_path, alert: "#{humanized_message}. #{t('custom.errors.resolve_duplicate')}."

        # penangan error null violation
        rescue ActiveRecord::NotNullViolation => e
          logger.error "#{Current.request_id} - NotNullViolation error: #{e.message}"
          error_column = e.message.match(/column "(.*?)"/)[1] # Menangkap nama kolom yang menyebabkan error
          error_row = data.find { |r| r[error_column.to_sym].nil? }

          error_message = "#{t('activerecord.attributes.capital_proposal.' + error_column)} " \
            "#{I18n.t('errors.messages.blank')} (row: #{error_row.inspect})"
          return redirect_back_or_to import_admin_capital_proposals_path, alert: "#{t('custom.errors.import_failed')}: #{error_message}"

        # Penanganan umum untuk semua jenis error lainnya
        rescue => e
          logger.error "#{Current.request_id} - General error during import: #{e.message}"
          return redirect_back_or_to import_admin_capital_proposals_path, alert: t("custom.errors.general_error")

        end

        unless maybe_error
          logger.debug "#{Current.request_id} - IMPORT START TIME: #{start_time}, IMPORT END TIME: #{Time.now}"
          redirect_to admin_capital_proposals_path, notice: t("custom.flash.notices.successfully.imported", model: t("activerecord.models.capital_proposal"))
          nil
        end

      else
        redirect_back_or_to import_admin_capital_proposals_path, alert: t("custom.flash.alerts.select_file")
      end
    end


    private

      def capital_proposal_params
        params.expect(capital_proposal: [
          :number,
          :real_number,
          :capital_proposal_type_id,
          :capital_proposal_group_id,
          :site_id,
          :department_id,
          :date,
          :description,
          :currency_id,
          :equiv_amount,
          :rate,
          :budget_ref_number,
          :budget_amount,
          :status
        ])
      end

      def set_capital_proposal
        @capital_proposal = CapitalProposal.find(params[:id])
        @capital_proposal.date = @capital_proposal.date.strftime("%Y-%m-%d")
        @capital_proposal.equiv_amount = @capital_proposal.equiv_amount.to_i
        @capital_proposal.rate = @capital_proposal.rate.to_i
        @capital_proposal.budget_amount = @capital_proposal.budget_amount.to_i
      end

      def set_function_access_code
        @function_access_code = FunctionAccessConstant::FA_ASS_CP
      end
  end
end
