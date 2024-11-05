import { Controller } from "@hotwired/stimulus"
import SlimSelect from "slim-select";
import { get } from "@rails/request.js"

// Connects to data-controller="slim-no-search"
export default class extends Controller {
  connect() {
    this.select = new SlimSelect({
      select: this.element,
      settings: {
        showSearch: false,
      }
    });
  }

  disconnect() {
    this.select.destroy();
  }
}
