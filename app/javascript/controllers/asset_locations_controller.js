import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select";
import { get } from "@rails/request.js"

// Connects to data-controller="asset-locations"
export default class extends Controller {
  static targets = [ "select" ]

  connect() {
    console.log("asset locations controller")

    const tomSelect = new TomSelect(this.selectTarget,{
      plugins: {
        remove_button:{
          title:'Remove this item',
          className: "absolute top-0 right-0 p-2 hover:bg-red-300 hover:rounded-full"
        },
        clear_button:{
			    title:'Remove all selected options'
		    }
      },
      sortField: {
        field: 'text',
        direction: 'asc'
      },
      valueField: 'tagging_id',
      labelField: 'tagging_id',
      searchField: 'tagging_id',
      load: function(query, callback) {
        var url = `/admin/asset-management/asset-locations/search-asset?tagging_id=${encodeURIComponent(query)}`

        fetch(url)
          .then(response => response.json())
          .then(json => {
            callback(json.items)
          }).catch(() => {
            callback()
          })
      },

      // custom rendering functions for options and items
      render: {
        option: function(item, escape) {
          return `
            <div class="rounded p-4">
              <div class="mb-1">
                  <span class="text-xl">${ escape(item.tagging_id) }</span>
              </div>
              <div class="flex flex-col">
                <div><span class="font-semibold">Current site:</span> ${ escape(item.site) }</div>
                <div><span class="font-semibold">Current user id:</span> ${ escape(item.user_asset_id)}</div>
                <div><span class="font-semibold">Current username:</span> ${ escape(item.user_asset_username)}</div>
              </div>
            </div>
          `;
        },
        item: function(item, escape) {
          return `
            <div class="rounded p-4">
              <div class="mb-1">
                  <span class="text-xl">${ escape(item.tagging_id) }</span>
              </div>
              <div class="flex flex-col">
                <div><span class="font-semibold">Current site:</span> ${ escape(item.site) }</div>
                <div><span class="font-semibold">Current user id:</span> ${ escape(item.user_asset_id)}</div>
                <div><span class="font-semibold">Current username:</span> ${ escape(item.user_asset_username)}</div>
              </div>
            </div>
          `;

        }
      },
    });

    // // Tangkap elemen kontrol baru yang dibuat oleh TomSelect
    // const controlElement = tomSelect.control_input;

    // // Tambahkan event listener pada elemen baru
    // controlElement.addEventListener('input', (event) => {
    //   this.debounce(() => this.searchAssetByTaggingId(event), 300); // 300ms
    // });
  }

  async searchAssetByTaggingId(event) {
    const taggingId = event.target.value

    if (taggingId) {
      // const responset = await get(`/admin/asset-management/asset-locations/search-asset?tagging_id=${taggingId}`, { headers: { Accept: "text/vnd.turbo-stream.html" } })
      try {
        const response = await fetch(`/admin/asset-management/asset-locations/search-asset?tagging_id=${taggingId}`, {
          headers: { Accept: "application/json" }
        })

        if (response.ok) {
          const results = await response.json()

          this.tomSelect.clearOptions()

          results.forEach(result => {
            this.tomSelect.addOption({ value: result.id, text: result.tagging_id })
          })

          this.tomSelect.refreshOptions()
        } else {
          console.error("Failed to fetch data!")
        }
      } catch (error) {
        console.error("error...", error)
    }
    }
  }

  debounce(callback, delay) {
    clearTimeout(this.timeout); // Hapus timer sebelumnya
    this.timeout = setTimeout(callback, delay); // Set timer baru
  }

}
