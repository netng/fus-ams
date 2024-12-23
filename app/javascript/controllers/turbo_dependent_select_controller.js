import { Controller } from "@hotwired/stimulus"
import SlimSelect from "slim-select";
import { get } from "@rails/request.js"


// Connects to data-controller="turbo-dependent-select"
export default class extends Controller {
  static targets = ["storageUnit", "select"]

  connect() {
    this.selectTargets.forEach((selectTarget) => {
      new SlimSelect({
        select: selectTarget
      });
    });
    console.log("turbo dependent select connected")
  }

  async loadRooms(event) {
    const inventoryLocationId = event.target.value
    if (inventoryLocationId) {
      await get(`/admin/entries/inventory_locations/rooms?query=${inventoryLocationId}`, { headers: { Accept: "text/vnd.turbo-stream.html" } })
    }
  }

  async loadStorageUnits(event) {
    const roomId = event.target.value
    if (roomId) {
      await get(`/admin/entries/inventory_locations/rooms_storage_units?query=${roomId}`, { headers: { Accept: "text/vnd.turbo-stream.html" } })
    }
  }

  async loadStorageUnitBins(event) {
    const storageUnitId = event.target.value
    if (storageUnitId) {
      await get(`/admin/entries/inventory_locations/rooms_storage_units_bins?query=${storageUnitId}`, { headers: { Accept: "text/vnd.turbo-stream.html" } })
    }
  }
}
