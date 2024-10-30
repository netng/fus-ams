module Admin
  class DeliveryOrdersController < ApplicationAdminController
    before_action :set_delivery_order, only: [:edit, :update, :destroy]
    before_action :set_function_access_code

    def index
      authorize :authorization, :index?

      @q = DeliveryOrder.ransack(params[:q])
      @q.sorts = ["date asc"] if @q.sorts.empty?
			scope = @q.result.includes(:purchase_order)
			@pagy, @delivery_orders = pagy(scope)
    end

    def new
      authorize :authorization, :create?

      @delivery_order = DeliveryOrder.new
    end

    def create
      authorize :authorization, :create?

      @delivery_order = DeliveryOrder.new(delivery_order_params)


      respond_to do |format|
        if @delivery_order.save
          format.html { redirect_to admin_delivery_orders_path, notice: t("custom.flash.notices.successfully.created", model: t("activerecord.models.delivery_order"))}
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
				if @delivery_order.update(delivery_order_params)
					format.html { redirect_to admin_delivery_orders_path, notice: t("custom.flash.notices.successfully.updated", model: t("activerecord.models.delivery_order")) }
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

      delivery_order_ids = params[:delivery_order_ids]

			ActiveRecord::Base.transaction do
				delivery_orders = DeliveryOrder.where(id: delivery_order_ids)

				delivery_orders.each do |delivery_order|
					unless delivery_order.destroy
            error_message = delivery_order.errors.full_messages.join("")
            redirect_to admin_delivery_orders_path, alert: "#{error_message} - #{t('activerecord.models.delivery_order')} id: #{delivery_order.id_delivery_order}"
            raise ActiveRecord::Rollback
					end
				end
				
				respond_to do |format|
					format.html { redirect_to admin_delivery_orders_path, notice: t("custom.flash.notices.successfully.destroyed", model: t("activerecord.models.delivery_order")) }
				end
			end
    end

    def import
      authorize :authorization, :create?
    end

    def process_import
      authorize :authorization, :create?
      allowed_extension = [".xlsx", ".csv"]
      file = params[:file]

      if file.present?
        if !allowed_extension.include?(File.extname(file.original_filename))
          return redirect_back_or_to import_admin_delivery_orders_path, alert: t("custom.errors.invalid_allowed_extension")
        end

        xlsx = Roo::Spreadsheet.open(file.path)

        sheet = xlsx.sheet(0)

        delivery_order_attributes_headers = {
          id_delivery_order: "Asset model id",
          name: "Name",
          brand: "Brand id",
          asset_type: "Asset type id",
          asset_item_type: "Asset item type id",
          description: "Description"
        }

        ActiveRecord::Base.transaction do
          begin
            sheet.parse(delivery_order_attributes_headers).each do |row|

              brand = Brand.find_by_id_brand(row[:brand])
              asset_type = AssetType.find_by_id_asset_type(row[:asset_type])
              asset_item_type = AssetItemType.find_by_id_asset_item_type(row[:asset_item_type])

              if brand.nil?
                redirect_back_or_to import_admin_delivery_orders_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.brand"), id: row[:brand])
                raise ActiveRecord::Rollback
              end

              if asset_type.nil?
                redirect_back_or_to import_admin_delivery_orders_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.asset_type"), id: row[:asset_type])
                raise ActiveRecord::Rollback
              end

              if asset_item_type.nil?
                redirect_back_or_to import_admin_delivery_orders_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.asset_item_type"), id: row[:asset_item_type])
                raise ActiveRecord::Rollback
              end

              delivery_order = DeliveryOrder.new(
                id_delivery_order: row[:id_delivery_order],
                name: row[:name],
                brand: brand,
                asset_type: asset_type,
                asset_item_type: asset_item_type,
                description: row[:description]
              )
  
              unless delivery_order.save
                error_message = delivery_order.errors.details.map do |field, error_details|
                  error_details.map do |error|
                    "[#{t("custom.errors.import_failed")}] - #{field.to_s.titleize} #{error[:value]} #{I18n.t('errors.messages.taken')}"
                  end
                end.flatten.join("")

                redirect_to import_admin_delivery_orders_path, alert: error_message
                raise ActiveRecord::Rollback
              end
            end
          rescue Roo::HeaderRowNotFoundError => e
            return redirect_to import_admin_delivery_orders_path, alert: t("custom.errors.invalid_import_template", errors: e)
          end

          respond_to do |format|
            format.html { redirect_to admin_delivery_orders_path, notice: t("custom.flash.notices.successfully.imported", model: t("activerecord.models.delivery_order")) }
          end
        end
      else
        redirect_back_or_to import_admin_delivery_orders_path, alert: t("custom.flash.alerts.select_file")
      end
    end


    private

      def delivery_order_params
        params.expect(delivery_order: [ :number, :purchase_order_id, :date, :warranty_expired, :description ])
      end

      def set_delivery_order
        @delivery_order = DeliveryOrder.find(params[:id])
      end

      def set_function_access_code
				@function_access_code = FunctionAccessConstant::FA_ASS_DO
      end
  end
end