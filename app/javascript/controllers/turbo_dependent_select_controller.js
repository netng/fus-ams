import { Controller } from "@hotwired/stimulus"
import SlimSelect from "slim-select";
import TomSelect from "tom-select";
import { get } from "@rails/request.js"


// Connects to data-controller="turbo-dependent-select"
export default class extends Controller {
  static targets = ["storageUnit", "select"]
  static values = { endpoint: String }

  connect() {
    this.selectTargets.forEach((selectTarget) => {
      // Periksa apakah Tom-Select sudah diinisialisasi
      if (!selectTarget.tomSelect) {
        new TomSelect(selectTarget, {
          allowEmptyOption: true
        });
      }
    });

    console.log("Tom-Select initialized for dependent selects");
  }

  disconnect() {
    this.selectTargets.forEach((selectTarget) => {
      if (selectTarget.tomSelect) {
        selectTarget.tomSelect.destroy(); // Hancurkan instance Tom-Select saat controller dilepas
      }
    });
    console.log("Tom-Select destroyed");
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
}
