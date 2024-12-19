import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dynamic-remove"
export default class extends Controller {
  static targets = ["destroyField", "container"]

  connect() {
    console.log("dynamic remove connected")
  }

  removeDetail(event) {
    event.preventDefault();

    const row = event.currentTarget.closest('[data-dynamic-remove-target="container"]');
    const destroyField = row.querySelector('[data-dynamic-remove-target="destroyField"]');

    if (destroyField) {
      destroyField.value = 1
    }

    if (row) {
      row.querySelectorAll("input, select, textarea").forEach((input) => {
        input.removeAttribute("required");
      });
      row.style.display = "none"
      console.log("row ", row)
    }
  }
}
