// controllers/scroll_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["frame"];

  connect() {
    console.log("Scroll controller connected");
  }

  scrollToBottom() {
    if (this.hasFrameTarget) {
      this.frameTarget.scrollTop = this.frameTarget.scrollHeight;
    }
  }

  observeMutations() {
    const observer = new MutationObserver(() => {
      this.scrollToBottom(); // Scroll otomatis ke bawah saat konten berubah
    });

    if (this.hasFrameTarget) {
      observer.observe(this.frameTarget, { childList: true, subtree: true });
    }
  }

  frameTargetConnected() {
    this.observeMutations();
  }
}
