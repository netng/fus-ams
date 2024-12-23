import { Controller } from "@hotwired/stimulus"
import SlimSelect from "slim-select";
import TomSelect from "tom-select";
import { get } from "@rails/request.js"


// Connects to data-controller="turbo-dependent-select"
export default class extends Controller {
  static targets = ["storageUnit", "select"]

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

  async loadRooms(event) {
    const inventoryLocationId = event.target.value
    if (inventoryLocationId) {
      await get(`/admin/entries/inventory_locations/rooms?query=${inventoryLocationId}`, { headers: { Accept: "text/vnd.turbo-stream.html" } })
    } else {
      await get(`/admin/entries/inventory_locations/rooms?query=${inventoryLocationId}`, { headers: { Accept: "text/vnd.turbo-stream.html" } })
    }
  }

  async loadStorageUnits(event) {
    const roomId = event.target.value
    if (roomId) {
      await get(`/admin/entries/inventory_locations/rooms_storage_units?query=${roomId}`, { headers: { Accept: "text/vnd.turbo-stream.html" } })
    } else {
      await get(`/admin/entries/inventory_locations/rooms_storage_units?query=${roomId}`, { headers: { Accept: "text/vnd.turbo-stream.html" } })
    }
  }

  async loadStorageUnitBins(event) {
    const storageUnitId = event.target.value
    if (storageUnitId) {
      await get(`/admin/entries/inventory_locations/rooms_storage_units_bins?query=${storageUnitId}`, { headers: { Accept: "text/vnd.turbo-stream.html" } })
    } else {
      await get(`/admin/entries/inventory_locations/rooms_storage_units_bins?query=${storageUnitId}`, { headers: { Accept: "text/vnd.turbo-stream.html" } })
    }
  }
}
