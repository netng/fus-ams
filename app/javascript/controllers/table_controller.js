import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="table"
export default class extends Controller {
  static targets = [
    "parentCheckbox",
    "childCheckbox",
    "deleteButton",
    "table",
  ]

  connect() {
     this.initInitialState()
  }

  initInitialState() {
    this.childCheckboxTargets.map(x => x.checked = false)
    this.initParentChecboxStatus()
    this.initDeleteButtonStatus()
  }

  resetDeleteButton() {
    if (this.childCheckboxCheckedCount > 0) {
      this.deleteButtonTarget.disabled = true
      this.deleteButtonTarget.classList.replace("bg-red-500", "bg-slate-300")
      this.resetDeleteButtonTextContent()
    }
  }

  toggleChildCheckbox() {
    if (this.hasParentCheckboxTarget) {
      if (this.parentCheckboxTarget.checked) {
        this.childCheckboxTargets.map(x => x.checked = true)
      } else {
        this.childCheckboxTargets.map(x => x.checked = false)
      }
    }

    this.initDeleteButtonStatus()
  }

  toggleParentCheckbox() {
    if (this.hasParentCheckboxTarget) {
      if (this.childCheckboxTargets.map(x => x.checked).includes(false)) {
        this.parentCheckboxTarget.checked = false
      } else {
        this.parentCheckboxTarget.checked = true
      }
    }

    this.initDeleteButtonStatus()
  }

  updateCount() {
    const count = this.childCheckboxCheckedCount
    
    if (count > 0) {
      if (this.hasDeleteButtonTarget) {
        this.resetDeleteButtonTextContent()
        this.deleteButtonTarget.textContent += count > 0 ? ` (${count})` :  ''
      }
    } else {
      this.resetDeleteButtonTextContent()
    }
  }

  resetDeleteButtonTextContent() {
    this.deleteButtonTarget.textContent = this.deleteButtonTarget.textContent.replace(/\s?\(\d+\)/, '')
  }

  initDeleteButtonStatus() {
    const count = this.childCheckboxCheckedCount
    if (this.hasDeleteButtonTarget) {
      if (count > 0) {
        this.deleteButtonTarget.disabled = false
        this.deleteButtonTarget.classList.replace("bg-slate-300", "bg-red-500")
        this.deleteButtonTarget.focus()
        this.updateCount()
      } else {
        this.deleteButtonTarget.disabled = true
        this.deleteButtonTarget.classList.replace("bg-red-500", "bg-slate-300")
        this.updateCount()
      }
    }
  }


  initParentChecboxStatus() {
    requestAnimationFrame(() => {
      if (this.hasParentCheckboxTarget) {
        if (this.childCheckboxTargets.length === 0) {
          this.parentCheckboxTarget.disabled = true
          this.parentCheckboxTarget.checked = false
        } else {
          this.parentCheckboxTarget.disabled = false
          this.parentCheckboxTarget.checked = false
        }
      }
      
    })
  }

  initParentRestoreChecboxStatus() {
    requestAnimationFrame(() => {
      if (this.hasParentRestoreTarget) {
        if (this.childRestoreTargets.length === 0) {
          this.parentRestoreTarget.disabled = true
          this.parentRestoreTarget.checked = false
        } else {
          this.parentRestoreTarget.disabled = false
          this.parentRestoreTarget.checked = false
        }
      }
      
    })
  }

  setAutoFocusToAddButton() {
    const btnAdd = document.querySelector("button[autofocus]")
    if (btnAdd) {
      btnAdd.focus()
    }
  }

  toggleEmptyState() {
    setTimeout(() => {
      requestAnimationFrame(() => {
        if (this.hasEmptyStateTarget) {
          if (this.tableTarget.rows.length > 1) {
              this.emptyStateTarget.style.display = "none"
          } else {
            this.emptyStateTarget.style.display = "revert"
            this.setAutoFocusToAddButton()
          }
        }
      })
    }, 100)
  }

  get childCheckboxCheckedCount() {
    return this.childCheckboxTargets.filter((child) => child.checked).length;
  }

  get childRestoreCheckboxCheckedCount() {
    return this.childRestoreTargets.filter((child) => child.checked).length;
  }

}
