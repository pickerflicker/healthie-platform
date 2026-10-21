import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog"]

  open(event) {
    this.trigger = event.currentTarget
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
  }

  cancel(event) {
    event.preventDefault()
    this.close()
  }

  restoreFocus() {
    if (this.trigger?.isConnected) this.trigger.focus()
  }

  reset() {
    this.dialogTarget.close()
  }
}
