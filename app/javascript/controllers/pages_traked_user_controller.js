import { Controller } from "@hotwired/stimulus"
import { FetchRequest } from '@rails/request.js'

// Connects to data-controller="ui-video-js"
export default class extends Controller {
  connect() {
    this.visibilitychange = this.visibilitychange.bind(this)
    this.beforeunload = this.beforeunload.bind(this)

    document.addEventListener("visibilitychange", this.visibilitychange)
    window.addEventListener("beforeunload", this.beforeunload)
  }

  disconnect() {
    document.removeEventListener("visibilitychange", this.visibilitychange)
    window.removeEventListener("beforeunload", this.beforeunload)
  }

  visibilitychange(event) {
    let action = document.hidden ? "Guia ativa" : "Guia em segundo plano"
    this.sendActivity(action)
  }

  beforeunload(event) {
    this.sendActivity("Fechou a página")
  }

  async sendActivity(action) {
    const request = new FetchRequest('post', '/users/histories', {
      body: JSON.stringify({
        history: {
          action: action
        }
      })
    })
    const response = await request.perform()

    // if (response.ok) {
    //   const body = await response.text
    // }
  }
}
