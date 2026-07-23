import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.observer = new MutationObserver(() => this.playLatestAssistantAudio())
    this.observer.observe(this.element, { childList: true, subtree: true })
    this.playLatestAssistantAudio()
  }

  disconnect() {
    this.observer?.disconnect()
  }

  playLatestAssistantAudio() {
    const players = this.element.querySelectorAll("[data-assistant-audio='true']")
    const latestPlayer = players[players.length - 1]

    if (!latestPlayer || latestPlayer.dataset.played === "true") return

    players.forEach((player) => {
      if (player !== latestPlayer) player.dataset.assistantAudio = "false"
    })

    latestPlayer.dataset.played = "true"
    latestPlayer.play().catch(() => {})
  }
}
