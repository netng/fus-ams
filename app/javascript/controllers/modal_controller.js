import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="modal"
export default class extends Controller {
  static targets = ["modal", "modalContent"]
  static values = { previousUrl: String }

  connect() {
    document.body.classList.add('overflow-hidden')
  }

  disconnect() {
    document.body.classList.remove('overflow-hidden')
  }

  // hide modal
  // action: "modal#hideModal"
  // hideModal() {
  //   if (this.previousUrlValue) {
  //     this.modalTarget.remove()
  //     // update browser history
  //     history.replaceState({}, "", this.previousUrlValue);
  //   } else {
  //     this.modalTarget.remove()
  //   }
    
  //   // clean up modal content
  //   const frame = document.getElementById('modal')
  //   frame.removeAttribute("src")
  // }

  // stacked hide modal
  hideModal(event) {

    // Jika event ada (misalnya dari tombol Cancel)
    if (event) {
      event.preventDefault()
      event.stopPropagation() // Hentikan hanya untuk tombol Cancel
    }

    // Hapus elemen modal ini saja
    this.element.remove()

    // Jika URL sebelumnya diatur, kembalikan ke URL sebelumnya
    if (this.previousUrlValue) {
      history.replaceState({}, "", this.previousUrlValue)
    }

    // Jika ini adalah modal terakhir, bersihkan turbo frame "modal"
    if (this.isTopModal()) {
      const frame = document.getElementById("modal")
      if (frame) {
        frame.removeAttribute("src")
      }
    }
  }

  
  // hide modal on successful form submission
  // action: "turbo:submit-end->modal#submitEnd"
  submitEnd(e) {
    if (e.detail.success) {
      this.hideModal()
    }
  }

  // hide modal when clicking ESC
  // action: "keyup@window->modal#closeWithKeyboard"
  closeWithKeyboard(e) {
    const loader = document.querySelector('.loader');

    // Cek apakah loader aktif (visible dan memiliki pointer-events)
    if (loader && getComputedStyle(loader).pointerEvents !== 'none') {
      // Jangan tutup modal jika loader aktif
      return;
    }

    if (e.code == "Escape" && this.isTopModal()) {
      this.hideModal()
    }
  }

  // hide modal when clicking outside of modal
  // action: "click@window->modal#closeBackground"
  closeBackground(e) {
    const loader = document.querySelector('.loader');

    // Cek apakah loader aktif (visible dan memiliki pointer-events)
    if (loader && getComputedStyle(loader).pointerEvents !== 'none') {
      // Jangan tutup modal jika loader aktif
      return;
    }

    if (this.isTopModal() && (!e || !this.modalContentTarget.contains(e.target))) {
      // return;
      this.hideModal()
    }
  }

  // Utility: Check if this is the top modal
  isTopModal() {
    const allModals = document.querySelectorAll("[data-controller='modal']")
    return allModals[allModals.length - 1] === this.element
  }

  preventCloseOnBusy(e) {
    const loader = document.querySelector('.[class~=busy]');

    // Cek apakah loader aktif (visible dan memiliki pointer-events)
    if (loader && getComputedStyle(loader).pointerEvents !== 'none') {
      // Jangan tutup modal jika loader aktif
      e.preventDefault();
      return;
    }
  }
}
