import { Controller } from "@hotwired/stimulus"
import SlimSelect from "slim-select";
import { get } from "@rails/request.js"

// Connects to data-controller="slim"
export default class extends Controller {
  connect() {
    this.select = new SlimSelect({
      select: this.element,
      settings: {
        allowDeselect: true,
        openPosition: 'down',
        appendTo: 'body',
      }
    });
  }

  disconnect() {
    this.select.destroy();
  }

  hello() {
    console.log("Hello")
    console.log(this.element)
    this.connect()
  }
}
