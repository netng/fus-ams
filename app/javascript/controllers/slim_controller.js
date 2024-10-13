import { Controller } from "@hotwired/stimulus"
import SlimSelect from "slim-select";
import { get } from "@rails/request.js"

// Connects to data-controller="slim"
export default class extends Controller {
  static targets = ["independent", "parent", "child"]

  connect() {
    this.parentSelect = new SlimSelect({select: this.parentTarget})
    this.childSelect = new SlimSelect({select: this.childTarget})

    this.independentTargets.forEach(selectElement => {
      new SlimSelect({ select: selectElement })
    })
  }

  disconnect() {
    this.parentSelect.destroy()
    this.childSelect.destroy()

    this.independentTargets.forEach(selectElement => {
      const slimSelectInstance = selectElement.slim
      if (slimSelectInstance) {
        slimSelectInstance.destroy()
      }
    })
  }

  changeChild() {
    console.log("changeChild")
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

          console.log("Response ", data)

          data.forEach(item => {
            items.push({ text: item.name, value: item.name })
          })

          console.log("Items ", items)
          childSelect.setData(items)
        }

      } catch (error) {
        console.error(error)
      }
    } else {
      childSelect.setData([{ text: defaultOption, value: '' }])

    }

  }

  // async loadItems() {
  //   const searchValue = this.assetTypeTarget.value
  //   const defaultOption = this.assetItemTypeTarget.dataset.defaultOption

  //   if (searchValue) {
  //     try {
  //       this.assetItemTypeSelect.setData([])

  //       const response = await get(`asset_models/asset_item_types?query=${searchValue}`, {
  //         responseKind: "json"
  //       })

  //       if (response.ok) {
  //         const data = await response.json

  //         const items = [{ text: defaultOption, value: '' }]

  //         data.forEach(item => {
  //           items.push({ text: item.name, value: item.name })
  //         })
          
  //         this.assetItemTypeSelect.setData(items)
  //       }
  //     } catch (error) {
  //       console.error(error)
  //     }
  //   }
  // }
}
