// app/javascript/controllers/active_menu_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["item"];

  connect() {
    this.updateActiveMenu();
  }

  activate(event) {
    // Hilangkan highlight dari semua <li>
    this.itemTargets.forEach((item) => {
      item.classList.remove("rounded", "bg-blue-200", "font-bold", "text-white");
      item.dataset.active = "false";
    });


    // Tambahkan highlight pada <li> yang diklik
    const clickedItem = event.currentTarget;
    clickedItem.classList.add("rounded", "bg-blue-200", "font-bold", "text-white");
    clickedItem.dataset.active = "true";

    // Simpan menu aktif ke localStorage
    localStorage.setItem("activeMenu", clickedItem.dataset.menu);
  }

  updateActiveMenu() {
    const currentUrl = window.location.pathname; // URL saat ini
    let activeMenu = localStorage.getItem("activeMenu");

    this.itemTargets.forEach((item) => {
      const menuPattern = item.dataset.menu; // Pattern menu dari <li>

      if (currentUrl === menuPattern) {
        item.classList.add("rounded", "bg-blue-200", "font-bold", "text-white");
        item.dataset.active = "true";
        activeMenu = menuPattern; // Set menu aktif
      } else {
        item.classList.remove("rounded", "bg-blue-200", "font-bold", "text-white");
        item.dataset.active = "false";
      }
    });

    // Simpan menu aktif ke localStorage
    if (activeMenu) {
      localStorage.setItem("activeMenu", activeMenu);
    }
  }
}
