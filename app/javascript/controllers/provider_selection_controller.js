import { Controller } from "@hotwired/stimulus"

// Show the complete selected identity when the native select's single line clips it.
export default class extends Controller {
  static targets = ["select", "name"]

  connect() {
    this.update()
  }

  update() {
    this.nameTarget.textContent = this.selectTarget.selectedOptions[0]?.textContent || ""
  }
}
