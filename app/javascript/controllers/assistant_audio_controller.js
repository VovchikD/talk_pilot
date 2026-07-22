import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.playLatestAssistantAudio()
  }

  playLatestAssistantAudio() {
    const latestPlayer = this.element.querySelector("[data-assistant-audio='true']")

    if (!latestPlayer || latestPlayer.dataset.played === "true") return

    latestPlayer.dataset.played = "true"
    latestPlayer.play().catch(() => {})
  }
}
