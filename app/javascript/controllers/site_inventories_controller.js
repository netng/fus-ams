import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select";
import { get } from "@rails/request.js"

// Connects to data-controller="site-inventories"
export default class extends Controller {
  static targets = [ "select" ]

  connect() {
    console.log("asset inventories connected")
    const tomSelect = new TomSelect(this.selectTarget,{
      plugins: {
        remove_button:{
          title:'Remove this item',
          className: "absolute top-0 right-0 p-2 hover:text-red-500 hover:font-bold"
        },
        clear_button:{
          title:'Remove all selected options'
        }
      },
      sortField: {
        field: 'text',
        direction: 'asc'
      },
      valueField: 'id',
      searchField: 'tagging_id',
      load: (query, callback) => {
        if (!this.siteId) {
          callback()
          return
        }

        var url = `/admin/inventory-management/inventory-movements/find-assets-by-site-inventory?tagging_id=${encodeURIComponent(query)}&site_id=${this.siteId}`

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
          const url = `/admin/asset-management/assets/${escape(item.asset_id)}`;

          return `
            <div class="rounded p-4">
              <div class="mb-1">
                  <span class="text-xl">${ escape(item.tagging_id) }</span>
              </div>
              <div>
                <a href="${url}" 
                  class="text-fus-blue hover:underline mt-2"
                  data-action="click->site-inventories#open"
                  data-turbo-frame="modal"
                  onclick="event.stopPropagation();">
                  View details
                </a>
              </div>
              
              <div class="flex flex-col">
                <div><span class="font-semibold">Site:</span> ${ escape(item.site) }</div>
                <div><span class="font-semibold">User asset id:</span> ${ escape(item.user_asset_id)}</div>
              </div>
            </div>
          `;
        },
        item: function(item, escape) {
          const url = `/admin/asset-management/assets/${escape(item.asset_id)}`;

          return `
            <div class="rounded p-4">
              <div class="mb-1">
                  <span class="text-xl">${ escape(item.tagging_id) }</span>
              </div>
              <div>
                <a href="${url}" 
                  class="text-blue-500 hover:underline mt-2"
                  data-action="click->site-inventories#open"
                  data-turbo-frame="modal"
                  onclick="event.stopPropagation();">
                  View Details
                </a>
              </div>
            </div>
          `;

        }
      },
    });

  }

  debounce(callback, delay) {
    clearTimeout(this.timeout); // Hapus timer sebelumnya
    this.timeout = setTimeout(callback, delay); // Set timer baru
  }

  open(event) {
    event.preventDefault(); // Mencegah navigasi default
    const url = event.currentTarget.href;

    // Set Turbo Frame untuk memuat konten
    const modalFrame = document.getElementById("modal");
    if (modalFrame) {
      modalFrame.src = url;
    }
  }

  updateSelectedSite(siteId) {
    this.siteId = siteId
  }
}
