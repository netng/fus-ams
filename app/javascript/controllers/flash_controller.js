import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="flash"
export default class extends Controller {
  static targets = ["flash"]
  connect() {
    this.autoHide()
  }

  autoHide() {
    this.flashTarget.addEventListener("animationend", () => {
      this.removeElement()
    })
  }

  removeElement() {
    this.element.remove()
  }

  hide() {
    this.removeElement()
  }
}
