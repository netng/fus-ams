module Admin
  class PurchaseOrdersController < ApplicationAdminController
    before_action :set_purchase_order, only: [:edit, :update, :destroy]
    before_action :set_function_access_code
    before_action :set_request_for_purchases, only: [:new, :create]

    def index
      authorize :authorization, :index?

      @q = PurchaseOrder.ransack(params[:q])
      @q.sorts = ["date asc"] if @q.sorts.empty?
			scope = @q.result.includes(:vendor, :request_for_purchase, :ship_to_site, :approved_by)
			@pagy, @purchase_orders = pagy(scope)
    end

    def new
      authorize :authorization, :create?

      @purchase_order = PurchaseOrder.new
      @request_for_purchase_details = RequestForPurchaseDetail.where(request_for_purchase_id: params[:request_for_purchase_id])
      @selected_details = []
    end

    def create
      authorize :authorization, :create?

      @purchase_order = PurchaseOrder.new(purchase_order_params)
      @purchase_order.date ||= Date.today.strftime("%Y-%m-%d")
      @selected_details = (params[:selected_details] || []).map(&:to_s)
      @request_for_purchase_details = RequestForPurchaseDetail.where(request_for_purchase_id: params[:request_for_purchase_id])



      puts @request_for_purchase_details.inspect

      puts "SELECTED DETAILS : #{params.inspect}"

      respond_to do |format|
        if @purchase_order.save
          format.html { redirect_to admin_purchase_orders_path, notice: t("custom.flash.notices.successfully.created", model: t("activerecord.models.purchase_order"))}
        else
          # format.html { render ("_form" if turbo_frame_request?), locals: { purchase_order: @purchase_order } }
          @request_for_purchase_details = RequestForPurchaseDetail.where(request_for_purchase_id: @purchase_order.id)
          format.html { render :new, status: :unprocessable_entity, locals: { rfp_details: @request_for_purchase_details ,selected_details: @selected_details } }
        end
      end
    end

    def edit
    end

    def update
    end

    def destroy
    end

    def load_rfp_details
      authorize :authorization, :create?
      
      @request_for_purchase_details = RequestForPurchaseDetail.where(request_for_purchase_id: params[:id])
      @selected_details = (params[:selected_details] || []).map(&:to_s)
      
      render turbo_stream: turbo_stream.replace(
        "rfp_details_table",
        partial: "admin/purchase_orders/rfp_details_table",
        locals: { rfp_details: @request_for_purchase_details, selected_details: @selected_details })

      puts @request_for_purchase_details.inspect
    end

    private
      def purchase_order_params
        params.expect(purchase_order: [ 
          :number,
          :date,
          :vendor_id,
          :request_for_purchase_id,
          :delivery_date,
          :ship_to_site_id,
          :payment_remarks,
          :approved_by_id,
          :status
        ])
      end

      def set_purchase_order
        @purchase_order = RequestForPurchase.find(params[:id])
        @purchase_order.date = @purchase_order.date.strftime("%Y-%m-%d")
        @purchase_order.delivery_date = @purchase_order.delivery_date.strftime("%Y-%m-%d")
      end

      def set_function_access_code
        @function_access_code = FunctionAccessConstant::FA_ASS_PO
      end

      def set_request_for_purchases
        @request_for_purchases = RequestForPurchase
          .joins(:request_for_purchase_details)
          .where(request_for_purchase_details: { purchase_order: nil})
          .group("request_for_purchases.id")
      end
  end
end
