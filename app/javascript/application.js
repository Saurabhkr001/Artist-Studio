// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

import { Turbo } from "@hotwired/turbo-rails"

Turbo.config.forms.confirm = function(message, element) {
  return new Promise((resolve) => {
    const dialog = document.getElementById("turbo-confirm")
    document.getElementById("turbo-confirm-message").textContent = message

    const confirmButton = document.getElementById("turbo-confirm-accept")
    confirmButton.textContent = element.getAttribute("data-confirm-button-text") || "Confirm"

    dialog.returnValue = ""
    dialog.showModal()

    dialog.addEventListener("close", () => {
      resolve(dialog.returnValue === "confirm")
    }, { once: true })
  })
}