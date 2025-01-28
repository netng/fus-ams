import { Controller } from "@hotwired/stimulus"
import SlimSelect from "slim-select";
import TomSelect from "tom-select";
import { get } from "@rails/request.js"


// Connects to data-controller="turbo-dependent-select"
export default class extends Controller {
  static targets = ["storageUnit", "select"]
  static values = { endpoint: String }
  static outlets = [ "inventory-location" ]

  connect() {
    this.selectTargets.forEach((selectTarget) => {
      // Periksa apakah Tom-Select sudah diinisialisasi
      if (!selectTarget.tomSelect) {
        new TomSelect(selectTarget, {
          allowEmptyOption: true
        });
      }
    });
  }

  disconnect() {
    this.selectTargets.forEach((selectTarget) => {
      if (selectTarget.tomSelect) {
        selectTarget.tomSelect.destroy(); // Hancurkan instance Tom-Select saat controller dilepas
      }
    });
  }

  async loadInventoryLocations(event) {
    const siteId = event.target.value
    const endpoint = this.endpointValue

    if (siteId) {
      await get(`${endpoint}?query=${siteId}`, { headers: { Accept: "text/vnd.turbo-stream.html" } })
    } else {
      await get(`${endpoint}?query=${siteId}`, { headers: { Accept: "text/vnd.turbo-stream.html" } })
    }
  }

  async loadRooms(event) {
    const inventoryLocationId = event.target.value
    const endpoint = this.endpointValue

    if (inventoryLocationId) {
      await get(`${endpoint}?query=${inventoryLocationId}`, { headers: { Accept: "text/vnd.turbo-stream.html" } })
    } else {
      await get(`${endpoint}?query=${inventoryLocationId}`, { headers: { Accept: "text/vnd.turbo-stream.html" } })
    }
  }

  async loadStorageUnits(event) {
    const roomId = event.target.value
    const endpoint = this.endpointValue

    if (roomId) {
      await get(`${endpoint}?query=${roomId}`, { headers: { Accept: "text/vnd.turbo-stream.html" } })
    } else {
      await get(`${endpoint}?query=${roomId}`, { headers: { Accept: "text/vnd.turbo-stream.html" } })
    }
  }

  async loadStorageUnitBins(event) {
    const storageUnitId = event.target.value
    const endpoint = this.endpointValue

    if (storageUnitId) {
      await get(`${endpoint}?query=${storageUnitId}`, { headers: { Accept: "text/vnd.turbo-stream.html" } })
    } else {
      await get(`${endpoint}?query=${storageUnitId}`, { headers: { Accept: "text/vnd.turbo-stream.html" } })
    }
  }

  // method outlet, memanggil fungsi pada stimulus controller inventory-location
  updateSiteId(event) {
    const siteId = event.target.value
    this.inventoryLocationOutlet.updateSiteId(siteId)
  }
}
