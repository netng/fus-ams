import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="tom-select"
export default class extends Controller {
  static targets = ["select"]

  connect() {
    new TomSelect(this.selectTarget,{
      create: true,
      sortField: {
        field: 'text',
        direction: 'asc'
      }
    });
  }
}
