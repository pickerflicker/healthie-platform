import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["message"]

  start() {
    this.element.setAttribute("aria-busy", "true")
    this.messageTarget.hidden = false
  }

  finish() {
    this.element.removeAttribute("aria-busy")
    this.messageTarget.hidden = true
  }
}
