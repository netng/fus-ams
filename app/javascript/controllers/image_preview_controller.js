import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="image-preview"
export default class extends Controller {
  static targets = ["fileInput", "fileName", "preview"]

  connect() {
    console.log("Image preview controller connected")
  }

  preview() {
    const file = this.fileInputTarget.files[0]

    if (file) {
      const reader = new FileReader()

      reader.onload = (event) => {
        this.previewTarget.src = event.target.result
        this.previewTarget.classList.remove("hidden") // Show the image preview
        this.fileNameTarget.textContent = file.name // Display file name
        this.fileNameTarget.classList.remove("hidden")
      }

      reader.readAsDataURL(file)
    } else {
      this.previewTarget.src = ""
      this.previewTarget.classList.add("hidden") // Hide the image preview
      this.fileNameTarget.textContent = ""
      this.fileNameTarget.classList.add("hidden")
    }
  }
}
