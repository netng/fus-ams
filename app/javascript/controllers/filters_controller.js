import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="filters"
export default class extends Controller {
  static outlets = ["table"]

  static values = {
    delay: {
        type: Number,
        default: 0
    }
  }

  connect() {
    console.log("Filters controller connected")
    if (this.delayValue) {
      console.log(this.delayValue)
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
    console.log(this.delayValue)
    console.log("search...")
    this.element.requestSubmit()
    this.resetDeleteButton()
  }

  resetDeleteButton() {
    this.tableOutlets.forEach(table => table.resetDeleteButton())
  }
}
