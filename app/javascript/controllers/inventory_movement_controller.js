import { Controller } from "@hotwired/stimulus"
import { get } from "@rails/request.js"

// Connects to data-controller="inventory-movement"
export default class extends Controller {
  static targets = ["movementType", "userAsset", "site", "siteSelect"]
  static values = { endPoint: String }
  static outlets = [ "user-assets", "site-inventories" ]

  connect() {
    console.log("inventory movement controller is connected")
  }

  toggleUserOrSite() {
    const type = this.movementTypeTarget.value
    const userAsset = this.userAssetTarget
    const site = this.siteTarget
    const userSelect = this.userAssetTarget.querySelector("select")
    const destinationSiteSelect = this.siteTarget.querySelector("select")

    if (type === "DIRECT_ISSUE") {
      this.userAssetTarget.classList.remove("hidden")
      this.siteTarget.classList.add("hidden")
      if (destinationSiteSelect) {
        destinationSiteSelect.removeAttribute("required")
      }
    }
    
    if (type === "SITE_TRANSFER") {
      this.siteTarget.classList.remove("hidden")
      this.userAssetTarget.classList.add("hidden")
      if (userSelect) {
        userSelect.removeAttribute("required")
      }
    }
  }

  updateSelectedSite() {
    console.log("selected site: ", this.siteSelectTarget.value)
    const siteId = this.siteSelectTarget.value
    this.userAssetsOutlet.updateSelectedSite(siteId)
    this.siteInventoriesOutlet.updateSelectedSite(siteId)
  }

}
