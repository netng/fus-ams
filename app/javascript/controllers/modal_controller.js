import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="modal"
export default class extends Controller {
  static targets = ["modal", "modalContent"]
  static values = { previousUrl: String }

  connect() {
    document.body.classList.add('overflow-hidden')
  }

  disconnect() {
    document.body.classList.remove('overflow-hidden')
  }

  // hide modal
  // action: "modal#hideModal"
  hideModal() {
    if (this.previousUrlValue) {
      this.modalTarget.remove()
      // update browser history
      history.replaceState({}, "", this.previousUrlValue);
    } else {
      this.modalTarget.remove()
    }
    
    // clean up modal content
    const frame = document.getElementById('modal')
    frame.removeAttribute("src")
  }

  
  // hide modal on successful form submission
  // action: "turbo:submit-end->modal#submitEnd"
  submitEnd(e) {
    if (e.detail.success) {
      this.hideModal()
    }
  }

  // hide modal when clicking ESC
  // action: "keyup@window->modal#closeWithKeyboard"
  closeWithKeyboard(e) {
    if (e.code == "Escape") {
      this.hideModal()
    }
  }

  // hide modal when clicking outside of modal
  // action: "click@window->modal#closeBackground"
  closeBackground(e) {
    if (e && this.modalContentTarget.contains(e.target)) {
      return;
    }
    this.hideModal()
  }

}
