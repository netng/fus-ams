import { Controller } from "@hotwired/stimulus"
import { get } from "@rails/request.js"
import SlimSelect from "slim-select";


// Connects to data-controller="po-rfp-details"
export default class extends Controller {
  static targets = ["select"]
  static values = { poId: String }

  connect() {
    this.select = new SlimSelect({
      select: this.element,
      settings: {
        allowDeselect: true,
      }
    });
  }

  disconnect() {
    this.select.destroy();
  }

  async loadDetails() {
    const requestForPurchaseId = this.selectTarget.value
    const po_id = this.poIdValue;
    let endpoint = `/admin/purchase_orders/load_rfp_details?id=${requestForPurchaseId}`;
    if (po_id) {
      endpoint += `&po_id=${po_id}`;
    }

    const response = await get(endpoint, {
      responseKind: "turbo-stream"
    })

    if (!response.ok) {
      console.error("failed to fetch rfp details")
    }
  }

  updateTable() {
    this.loadDetails()
  }
}
