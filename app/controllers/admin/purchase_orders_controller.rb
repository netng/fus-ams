module Admin
  class PurchaseOrdersController < ApplicationAdminController
    before_action :set_purchase_order, only: [:edit, :update, :destroy]
    before_action :set_function_access_code
    before_action :set_request_for_purchases, only: [:new, :create, :edit, :update]

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
      @selected_details = []
    end

    def create
      authorize :authorization, :create?

      @purchase_order = PurchaseOrder.new(purchase_order_params)
      @purchase_order.date ||= Date.today.strftime("%Y-%m-%d")
      @selected_details = (params[:selected_details] || []).map(&:to_s)
      @request_for_purchase_details = RequestForPurchaseDetail.where(request_for_purchase_id: params[:purchase_order][:request_for_purchase_id])
      @purchase_order.currency = @request_for_purchase_details.first.currency unless @request_for_purchase_details.empty?
      @purchase_order.rate = @request_for_purchase_details.first.rate unless @request_for_purchase_details.empty?


      respond_to do |format|
        ActiveRecord::Base.transaction do
          if @purchase_order.save
            @selected_details.each do |selected_id|
              @purchase_order.request_for_purchase.request_for_purchase_details.find(selected_id).update_attribute(:purchase_order, @purchase_order)
            end
            amount_by_currency = @purchase_order.request_for_purchase_details.select(:qty, :price).sum { |detail| detail.price * detail.qty }
            amount_by_rate = amount_by_currency * @purchase_order.rate
            @purchase_order.update_attribute(:amount_by_currency, amount_by_currency)
            @purchase_order.update_attribute(:amount_by_rate, amount_by_rate)
            format.html { redirect_to admin_purchase_orders_path, notice: t("custom.flash.notices.successfully.created", model: t("activerecord.models.purchase_order"))}
          else
            raise ActiveRecord::Rollback
          end
        end
        # format.html { render ("_form" if turbo_frame_request?), locals: { purchase_order: @purchase_order } }
        format.html { render :new, status: :unprocessable_entity }
      end
    end

    def edit
      authorize :authorization, :update?
      @purchase_order.date ||= Date.today.strftime("%Y-%m-%d")
      @selected_details = @purchase_order.request_for_purchase_details.pluck(:id).map { |id| id}

      rfp_details = @purchase_order.request_for_purchase_details
      unused_rfp_details = RequestForPurchaseDetail.where(request_for_purchase: @purchase_order.request_for_purchase, purchase_order: nil)
      @request_for_purchase_details = rfp_details + unused_rfp_details 

      request_for_purchase_by_current_po = RequestForPurchase.find(@purchase_order.request_for_purchase.id)
      @request_for_purchases = @request_for_purchases.to_a
      @request_for_purchases << request_for_purchase_by_current_po
      @request_for_purchases = @request_for_purchases.uniq

    end

    def update
      authorize :authorization, :update?
      @selected_details = (params[:selected_details] || []).map(&:to_s)

      rfp_details = @purchase_order.request_for_purchase_details
      unused_rfp_details = RequestForPurchaseDetail.where(request_for_purchase: @purchase_order.request_for_purchase, purchase_order: nil)
      @request_for_purchase_details = rfp_details + unused_rfp_details 

      request_for_purchase_by_current_po = RequestForPurchase.find(@purchase_order.request_for_purchase.id)
      @request_for_purchases = @request_for_purchases.to_a
      @request_for_purchases << request_for_purchase_by_current_po
      @request_for_purchases = @request_for_purchases.uniq

      prev_selected_details = @purchase_order.request_for_purchase_details.pluck(:id).map { |id| id}
      prev_request_for_purchase = @purchase_order.request_for_purchase

      respond_to do |format|
        ActiveRecord::Base.transaction do
          if @purchase_order.update(purchase_order_params)
            puts "PO INSPECT: #{@purchase_order.inspect}"


            # jika rfp nya berubah
            if @purchase_order.request_for_purchase != prev_request_for_purchase
              # loop dan lakukan update value kolom purchase_order_id pada request_for_purchase_details table sesuai dengan data yang di select
              @selected_details.each do |selected_id|
                @purchase_order.request_for_purchase.request_for_purchase_details.find(selected_id).update_attribute(:purchase_order, @purchase_order)
              end
              # kembalikan ke nil kolom purchase_order_id pada rfp yang sebelumnya di select
              # agar bisa digunakan kembali oleh PO yang lain
              prev_request_for_purchase.request_for_purchase_details.where(id: prev_selected_details).update_all(purchase_order_id: nil)
              amount_by_currency = @purchase_order.request_for_purchase_details.select(:qty, :price).sum { |detail| detail.price * detail.qty }
              amount_by_rate = amount_by_currency * @purchase_order.rate
              @purchase_order.update_attribute(:amount_by_currency, amount_by_currency)
              @purchase_order.update_attribute(:amount_by_rate, amount_by_rate)
            else
              # jika rfp nya tidak beruah
              # bandingkan details yang diselect, apakah masih sama atau ada perubahan
              if prev_selected_details.sort != @selected_details.sort
                # jika ada perubahan, update terlebih dahulu kolom purchase_order_id pada request_for_purchase_details sesuai rfp saat ini menjadi nil
                # ini mungkin masih bisa dioptimasi, tapi kita lihat nanti
                prev_request_for_purchase.request_for_purchase_details.where(id: prev_selected_details).update_all(purchase_order_id: nil)

                # loop semua details terbaru yang di select
                @selected_details.each do |selected_id|
                  # update kolom purchase_order_id sesuai detail selected terbaru
                  @purchase_order.request_for_purchase.request_for_purchase_details.find(selected_id).update_attribute(:purchase_order, @purchase_order)
                end

                @purchase_order.rate = @purchase_order.request_for_purchase_details.first.rate unless @purchase_order.request_for_purchase_details.empty?

                amount_by_currency = @purchase_order.request_for_purchase_details.select(:qty, :price).sum { |detail| detail.price * detail.qty }
                puts "AMOUNT BY CURRENCY: #{amount_by_currency}"
                puts "RATE: #{@purchase_order.inspect}"
                amount_by_rate = amount_by_currency * @purchase_order.rate
                @purchase_order.update_attribute(:amount_by_currency, amount_by_currency)
                @purchase_order.update_attribute(:amount_by_rate, amount_by_rate)
              end
            end
            
            format.html { redirect_to admin_purchase_orders_path, notice: t("custom.flash.notices.successfully.updated", model: t("activerecord.models.purchase_order")) }
          else
            raise ActiveRecord::Rollback
          end
        end

				format.html { render :edit, status: :unprocessable_entity }
			end
    end

    def destroy
      authorize :authorization, :destroy?

    end

    def destroy_many
      authorize :authorization, :destroy?

      purchase_order_ids = params[:purchase_order_ids]

			ActiveRecord::Base.transaction do
				purchase_orders = PurchaseOrder.where(id: purchase_order_ids)

				purchase_orders.each do |purchase_order|
					unless purchase_order.destroy
            error_message = purchase_order.errors.full_messages.join("")
            redirect_to admin_purchase_orders_path, alert: "#{error_message} - #{t('activerecord.models.purchase_order')} id: #{purchase_order.id_purchase_order}"
            raise ActiveRecord::Rollback
					end
				end
				
				respond_to do |format|
					format.html { redirect_to admin_purchase_orders_path, notice: t("custom.flash.notices.successfully.destroyed", model: t("activerecord.models.purchase_order")) }
				end
			end
    end

    def load_rfp_details
      authorize :authorization, :create?

      purchase_order = PurchaseOrder.find(params[:po_id]) unless params[:po_id].blank?

      if purchase_order && purchase_order.persisted? && params[:id] == purchase_order.request_for_purchase.id
        rfp_details = purchase_order.request_for_purchase_details
        unused_rfp_details = RequestForPurchaseDetail.where(request_for_purchase: purchase_order.request_for_purchase, purchase_order: nil)
        @request_for_purchase_details = rfp_details + unused_rfp_details 
      else
        @request_for_purchase_details = RequestForPurchaseDetail.where(request_for_purchase_id: params[:id], purchase_order: nil)
      end
      
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
        @purchase_order = PurchaseOrder.find(params[:id])
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
