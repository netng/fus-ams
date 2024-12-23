import { Controller } from "@hotwired/stimulus"
import { get } from "@rails/request.js"
import SlimSelect from "slim-select";


// Connects to data-controller="asset-inventory-locations"
export default class extends Controller {
  static targets = ["select"]
  static values = { assetId: String }

  connect() {
    this.select = new SlimSelect({
      select: this.element,
      settings: {
        allowDeselect: true,
      }
    });

    console.log("asset inventory locations connected")
  }

  disconnect() {
    this.select.destroy();
  }

  async loadAssetInventoryLocations() {
    const siteId = this.selectTarget.value
    const asset_id = this.assetIdValue;

    let endpoint = `/admin/entries/assets/inventory_locations?id=${siteId}`;
    if (asset_id) {
      endpoint += `&asset_id=${asset_id}`;
    }

    const response = await get(endpoint, {
      responseKind: "turbo-stream"
    })

    if (!response.ok) {
      console.error("failed to fetch rfp details")
    }
  }

  updateTable() {
    this.loadAssetInventoryLocations()
  }
}
