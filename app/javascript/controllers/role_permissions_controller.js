import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["checkAll", "permission"];

  // Toggle semua checkbox permission dalam satu baris
  toggleMenu(event) {
    const routeId = event.target.dataset.route;
    const isChecked = event.target.checked;

    // Perbarui semua checkbox permission sesuai status "Select All"
    this.permissionTargets.forEach((checkbox) => {
      if (checkbox.dataset.route === routeId) {
        checkbox.checked = isChecked;
      }
    });
  }

  // Perbarui status "Select All" berdasarkan checkbox individu
  toggleRow(event) {
    const routeId = event.target.dataset.route;

    // Cek apakah semua checkbox dalam baris telah tercentang
    const allChecked = this.permissionTargets
      .filter((checkbox) => checkbox.dataset.route === routeId)
      .every((checkbox) => checkbox.checked);

    // Temukan checkbox "Select All" yang sesuai
    const parentCheckbox = this.checkAllTargets.find(
      (checkbox) => checkbox.dataset.route === routeId
    );

    if (parentCheckbox) {
      parentCheckbox.checked = allChecked;
    }
  }
}
