import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="filters"
export default class extends Controller {
  static outlets = ["table"]
  static targets = ["form"];

  static values = {
    delay: {
        type: Number,
        default: 0
    }
  }

  connect() {
    if (this.delayValue) {
      this.submit = this.debounce(this.submit.bind(this), this.delayValue) 
    }
  }

  debounce(fn, delay = 1000) {
    let timeoutId = null

    return (...args) => {
        clearTimeout(timeoutId)
        timeoutId = setTimeout(() => fn.apply(this, args), delay)
    }
  }

  submit(event) {
    this.element.requestSubmit()
    this.resetDeleteButton()
  }

  resetDeleteButton() {
    this.tableOutlets.forEach(table => table.resetDeleteButton())
  }

  nextFrame(event) {
    const form = this.formTarget;
    form.dataset.turboFrame = event.params.frame; // load the next frame
    form.requestSubmit();                         // after submitting the form
  }
}
