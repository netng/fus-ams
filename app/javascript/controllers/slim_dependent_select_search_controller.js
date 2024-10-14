import { Controller } from "@hotwired/stimulus"
import SlimSelect from "slim-select";
import { get } from "@rails/request.js"

// Connects to data-controller="slim-dependent-select-search"
export default class extends Controller {
  static targets = ["parent", "child"]

  connect() {
    this.parentSelect = new SlimSelect({select: this.parentTarget})
    this.childSelect = new SlimSelect({select: this.childTarget})
  }

  disconnect() {
    this.parentSelect.destroy()
    this.childSelect.destroy()
  }

  changeChild() {
    this.loadDependentItems(this.parentTarget, this.childSelect)
  }

  async loadDependentItems(parentElement, childSelect) {
    const parentValue = parentElement.value
    const defaultOption = childSelect.select.select.dataset.defaultOption
    const endpoint = parentElement.dataset.endpoint

    if (parentValue && endpoint) {
      try {
        childSelect.setData([])

        const response = await get(`${endpoint}?query=${parentValue}`, {
          responseKind: "json"
        })

        if (response.ok) {
          const data = await response.json
          const items = [{ text: defaultOption, value: '' }]

          data.forEach(item => {
            items.push({ text: item.name, value: item.name })
          })

          childSelect.setData(items)
        }

      } catch (error) {
        console.error(error)
      }
    } else {
      childSelect.setData([{ text: defaultOption, value: '' }])

    }

  }
}
