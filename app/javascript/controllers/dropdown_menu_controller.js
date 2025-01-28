import { Controller } from "@hotwired/stimulus";

// data-controller="dropdown-menu"
export default class extends Controller {
  static targets = ["menu"];
  static classes = ["hidden"];
  static values = { delay: { type: Number, default: 200 } };

  connect() {
    this.timeout = null;
  }

  show() {
    clearTimeout(this.timeout);
    this.menuTarget.classList.remove("hidden");
  }

  hide() {
    clearTimeout(this.timeout);
    this.timeout = setTimeout(() => {
      if (!this.element.matches(":hover") && !this.menuTarget.matches(":hover")) {
        this.menuTarget.classList.add("hidden");
      }
    }, this.delayValue);
  }

  toggle(event) {
    // event.preventDefault();
    this.menuTarget.classList.toggle("hidden");
  }

  disconnect() {
    clearTimeout(this.timeout);
  }
}
