import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="file-upload"
export default class extends Controller {
  static targets = ["fileName"];

  updateFileName(event) {
    const input = event.target;
    const fileName = input.files[0]?.name || "No file chosen";
    const fileNameElement = this.element.querySelector("#file-name");

    fileNameElement.textContent = fileName;
    fileNameElement.classList.remove("hidden");
  }
}
