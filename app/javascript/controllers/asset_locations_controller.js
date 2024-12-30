import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select";
import { get } from "@rails/request.js"

// Connects to data-controller="asset-locations"
export default class extends Controller {
  static targets = [ "select" ]

  connect() {
    console.log("asset locations controller connected")

    const tomSelect = new TomSelect(this.selectTarget,{
      sortField: {
        field: 'text',
        direction: 'asc'
      }
    });

    // Tangkap elemen kontrol baru yang dibuat oleh TomSelect
    const controlElement = tomSelect.control_input;

    // Tambahkan event listener pada elemen baru
    controlElement.addEventListener('input', (event) => {
      this.debounce(() => this.searchAssetByTaggingId(event), 300); // 300ms
    });
  }

  async searchAssetByTaggingId(event) {
    const taggingId = event.target.value

    if (taggingId) {
      await get(`/admin/asset-management/asset-locations/search-asset?tagging_id=${taggingId}`, { headers: { Accept: "text/vnd.turbo-stream.html" } })
    }
  }

  debounce(callback, delay) {
    clearTimeout(this.timeout); // Hapus timer sebelumnya
    this.timeout = setTimeout(callback, delay); // Set timer baru
  }

}
