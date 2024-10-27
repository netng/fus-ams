import { Controller } from "@hotwired/stimulus"
import { get } from "@rails/request.js"

// Connects to data-controller="po-rfp-details"
export default class extends Controller {
  static targets = ["select"]

  connect() {
    console.log("po rfp details contoller connected")
  }

  async loadDetails() {
    const requestForPurchaseId = this.selectTarget.value
    console.log(requestForPurchaseId)

    // if (requestForPurchaseId) {
      const response = await get(`/admin/purchase_orders/load_rfp_details?id=${requestForPurchaseId}`, {
        responseKind: "turbo-stream"
      })

      if (!response.ok) {
        console.error("failed to fetch rfp details")
      }
    // }
  }

  updateTable() {
    this.loadDetails()
  }
}
