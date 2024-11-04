import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dialog"
export default class extends Controller {
  static values = { previousUrl: String }
  static outlets = ["slim"]

  connect() {
    this.open()
    // needed because ESC key does not trigger close event
    // this.element.addEventListener("close", this.enableBodyScroll.bind(this))
    this.element.addEventListener("close", () => {
      this.enableBodyScroll.bind(this)
      this.close()
    })
    // this.initializeSlim()

  }

  initializeSlim() {
    if (this.slimOutlets.length > 0) {
      setTimeout(() => {
        this.slimOutlets.forEach(slim => {
          slim.hello()
          slim.connect()
        })
      }, 500)
    }
  }
  
  disconnect() {
    this.element.removeEventListener("close", () => {
      this.enableBodyScroll.bind(this)
      this.close()
    })
  }

  // hide modal on successful form submission
  // data-action="turbo:submit-end->turbo-modal#submitEnd"
  submitEnd(e) {
    if (e.detail.success) {
      this.close()
    }
  }

  open() {
    this.element.showModal()
    document.body.classList.add('overflow-hidden')
  }

  close() {
    if (this.previousUrlValue) {
      // Turbo.visit(previousUrl, { action: "advance" })
      this.element.close()
      history.replaceState({}, "", this.previousUrlValue);
    } else {
      this.element.close()
    }

    // clean up modal content
    const frame = document.getElementById('modal')
    frame.removeAttribute("src")
    frame.innerHTML = ""
  }

  enableBodyScroll() {
    document.body.classList.remove('overflow-hidden')
  }

  clickOutside(event) {
    if (event.target === this.element) {
      this.close()
    }
  }
}
