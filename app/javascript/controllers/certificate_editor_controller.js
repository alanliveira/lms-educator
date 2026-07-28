import { Controller } from "@hotwired/stimulus"

const FIXED_FIELDS = {
  verification_code: "Código de verificação",
  qr_code: "QR Code",
  description: "Descritivo do certificado",
  verification_seal: "Selo de verificação"
}

const DESCRIPTION_FIELDS = {
  nome_do_aluno: "Nome do aluno",
  data_conclucao: "Data de conclusão",
  titulo_curso: "Título do curso",
  carga_horaria: "Carga horária",
  nome_da_empresa: "Nome da empresa"
}

export default class extends Controller {
  static targets = [
    "canvas", "backgroundLayer", "elements", "background", "backgroundOpacity",
    "signatureList", "library", "selectedPanel", "selectedType", "textControls", "elementControls", "descriptionInput",
    "artworkControls", "sealControls", "descriptionControls", "signatureControls", "deleteElementButton",
    "selectedFontFamily", "selectedFontSize", "selectedColor", "selectedTextAlign", "selectedVerticalAlign", "selectedWidth",
    "selectedHeight", "selectedX", "selectedY"
  ]

  connect() {
    this.state = this.normalizeState(JSON.parse(this.elementsTarget.value || "{}"))
    this.selectedId = null
    this.dragged = null
    this.boundStartDrag = this.startDrag.bind(this)
    this.boundDrag = this.drag.bind(this)
    this.boundStopDrag = this.stopDrag.bind(this)
    this.boundPreviewBackground = this.previewBackground.bind(this)
    this.boundUpdateBackgroundOpacity = this.updateBackgroundOpacity.bind(this)
    this.boundSelectBackground = this.selectBackground.bind(this)

    this.canvasTarget.addEventListener("pointerdown", this.boundStartDrag)
    this.canvasTarget.addEventListener("click", this.boundSelectBackground)
    document.addEventListener("pointermove", this.boundDrag)
    document.addEventListener("pointerup", this.boundStopDrag)
    this.backgroundTarget.addEventListener("change", this.boundPreviewBackground)
    this.backgroundOpacityTarget.addEventListener("input", this.boundUpdateBackgroundOpacity)

    this.backgroundOpacityTarget.value = this.state.background_opacity
    this.applyBackgroundOpacity()
    this.renderElements()
    this.renderSignatures()
    this.renderLibrary()
    this.selectBackground()
  }

  disconnect() {
    this.canvasTarget.removeEventListener("pointerdown", this.boundStartDrag)
    this.canvasTarget.removeEventListener("click", this.boundSelectBackground)
    document.removeEventListener("pointermove", this.boundDrag)
    document.removeEventListener("pointerup", this.boundStopDrag)
    this.backgroundTarget.removeEventListener("change", this.boundPreviewBackground)
    this.backgroundOpacityTarget.removeEventListener("input", this.boundUpdateBackgroundOpacity)
  }

  normalizeState(state) {
    const defaults = {
      verification_code: { x: 50, y: 82, width: 32, height: 8 },
      qr_code: { x: 88, y: 42, width: 14, height: 14 },
      description: { x: 50, y: 48, width: 70, height: 14, font_size: 18 },
      verification_seal: { x: 88, y: 14, width: 12, height: 14 }
    }
    const elementLibrary = state.element_library || {}
    const normalized = {
      background_opacity: Number.isFinite(Number(state.background_opacity)) ? Number(state.background_opacity) : 1,
      signatures: Array.isArray(state.signatures) ? state.signatures.map(signature => this.normalizeElement(signature, { label: "Assinatura", width: 24, height: 10, font_size: 14 })) : [],
      signature_library: Array.isArray(state.signature_library) ? state.signature_library.map(signature => this.normalizeElement(signature, { label: "Assinatura", width: 24, height: 10, font_size: 14 })) : [],
      element_library: {}
    }
    Object.entries(defaults).forEach(([id, fallback]) => {
      if (elementLibrary[id]) {
        normalized.element_library[id] = this.normalizeElement(elementLibrary[id], fallback)
      } else {
        normalized[id] = this.normalizeElement(state[id], fallback)
      }
    })
    return normalized
  }

  normalizeElement(element, defaults = {}) {
    const value = element || {}
    return {
      ...defaults,
      ...value,
      x: this.number(value.x, defaults.x ?? 50),
      y: this.number(value.y, defaults.y ?? 50),
      width: this.number(value.width, defaults.width ?? 32),
      height: this.number(value.height, defaults.height ?? 10),
      font_family: value.font_family || defaults.font_family || "Arial",
      font_size: this.number(value.font_size, defaults.font_size || 16),
      color: value.color || defaults.color || "#111827",
      text_align: value.text_align || defaults.text_align || "center",
      vertical_align: value.vertical_align || defaults.vertical_align || "center"
    }
  }

  number(value, fallback) {
    return Number.isFinite(Number(value)) ? Number(value) : fallback
  }

  renderElements() {
    this.canvasTarget.querySelectorAll("[data-certificate-element]").forEach(element => element.remove())
    Object.entries(FIXED_FIELDS).forEach(([id, label]) => {
      if (this.state[id]) this.createElement(id, this.state[id], id === "description" ? this.descriptionPreview() : label)
    })
    this.state.signatures.forEach(signature => this.createElement(signature.id, signature, signature.label || "Assinatura"))
  }

  renderLibrary() {
    this.libraryTarget.innerHTML = ""
    Object.entries(FIXED_FIELDS).forEach(([id, label]) => {
      if (!this.state[id]) this.addLibraryItem(id, label)
    })
    this.state.signature_library.forEach(signature => this.addLibraryItem(signature.id, signature.label || "Assinatura"))
    if (!this.libraryTarget.children.length) {
      const empty = document.createElement("span")
      empty.className = "text-xs text-gray-500 dark:text-gray-400"
      empty.textContent = "Nenhum elemento removido"
      this.libraryTarget.appendChild(empty)
    }
  }

  addLibraryItem(id, label) {
    const button = document.createElement("button")
    button.type = "button"
    button.textContent = `Restaurar ${label}`
    button.dataset.action = "certificate-editor#restoreElement"
    button.dataset.elementId = id
    button.className = "rounded-lg border border-gray-300 px-3 py-2 text-xs font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-200 dark:hover:bg-gray-700"
    this.libraryTarget.appendChild(button)
  }

  createElement(id, element, label) {
    const node = document.createElement("div")
    node.dataset.certificateElement = id
    node.className = "absolute flex cursor-move select-none items-center justify-center overflow-hidden rounded border border-dashed border-gray-500 bg-white/75 p-2 text-center font-semibold shadow-sm whitespace-pre-line"
    node.textContent = label
    if (id === "qr_code") {
      node.innerHTML = '<span class="pointer-events-none text-xs font-bold leading-tight">QR<br>CODE</span>'
      node.style.backgroundImage = "repeating-conic-gradient(#111827 0% 25%, #fff 0% 50%)"
      node.style.backgroundSize = "12px 12px"
      node.style.backgroundBlendMode = "screen"
    }
    if (id === "verification_seal" && this.canvasTarget.dataset.sealUrl) {
      node.innerHTML = `<img src="${this.canvasTarget.dataset.sealUrl}" alt="Selo de verificação" class="h-full w-full object-contain">`
    }
    this.applyElementStyle(node, element)
    node.addEventListener("click", event => {
      event.stopPropagation()
      this.selectElement(id)
    })
    this.canvasTarget.appendChild(node)
  }

  applyElementStyle(node, element) {
    node.style.left = `${element.x}%`
    node.style.top = `${element.y}%`
    node.style.width = `${element.width}%`
    node.style.height = `${element.height}%`
    node.style.fontFamily = element.font_family
    node.style.fontSize = `${element.font_size}px`
    node.style.color = element.color
    node.style.textAlign = element.text_align
    node.style.justifyContent = element.text_align === "left" ? "flex-start" : element.text_align === "right" ? "flex-end" : "center"
    node.style.alignItems = element.vertical_align === "top" ? "flex-start" : element.vertical_align === "bottom" ? "flex-end" : "center"
    node.style.transform = "translate(-50%, -50%)"
  }

  startDrag(event) {
    const element = event.target.closest("[data-certificate-element]")
    if (!element || !this.canvasTarget.contains(element)) return

    event.preventDefault()
    this.selectElement(element.dataset.certificateElement)
    this.dragged = element
  }

  drag(event) {
    if (!this.dragged) return

    const bounds = this.canvasTarget.getBoundingClientRect()
    const position = {
      x: this.clamp(((event.clientX - bounds.left) / bounds.width) * 100),
      y: this.clamp(((event.clientY - bounds.top) / bounds.height) * 100)
    }
    const element = this.findElement(this.dragged.dataset.certificateElement)
    element.x = position.x
    element.y = position.y
    this.applyElementStyle(this.dragged, element)
    this.updateSelectedInputs()
    this.persist()
  }

  stopDrag() {
    this.dragged = null
  }

  selectElement(id) {
    const element = this.findElement(id)
    if (!element) return

    this.selectedId = id
    this.selectedPanelTarget.classList.remove("hidden")
    this.artworkControlsTarget.classList.add("hidden")
    this.sealControlsTarget.classList.toggle("hidden", id !== "verification_seal")
    this.descriptionControlsTarget.classList.toggle("hidden", id !== "description")
    this.signatureControlsTarget.classList.toggle("hidden", !id.startsWith("signature-"))
    this.selectedTypeTarget.textContent = this.labelFor(id, element)
    this.textControlsTarget.classList.toggle("hidden", id === "verification_seal")
    this.elementControlsTarget.classList.remove("hidden")
    this.deleteElementButtonTarget.classList.remove("hidden")
    this.updateSelectionOutline()
    this.updateSelectedInputs()
  }

  selectBackground(event) {
    if (event?.target.closest("[data-certificate-element]")) return

    this.selectedId = null
    this.selectedPanelTarget.classList.add("hidden")
    this.deleteElementButtonTarget.classList.add("hidden")
    this.artworkControlsTarget.classList.remove("hidden")
    this.sealControlsTarget.classList.add("hidden")
    this.descriptionControlsTarget.classList.add("hidden")
    this.signatureControlsTarget.classList.add("hidden")
    this.selectedTypeTarget.textContent = "Arte do certificado"
    this.textControlsTarget.classList.add("hidden")
    this.elementControlsTarget.classList.add("hidden")
    this.backgroundOpacityTarget.value = this.state.background_opacity
    this.updateSelectionOutline()
  }

  updateSelectionOutline() {
    this.canvasTarget.querySelectorAll("[data-certificate-element]").forEach(node => {
      node.classList.toggle("border-blue-600", node.dataset.certificateElement === this.selectedId)
      node.classList.toggle("border-2", node.dataset.certificateElement === this.selectedId)
      node.classList.toggle("ring-2", node.dataset.certificateElement === this.selectedId)
      node.classList.toggle("ring-blue-300", node.dataset.certificateElement === this.selectedId)
      node.classList.toggle("border-dashed", node.dataset.certificateElement !== this.selectedId)
      node.classList.toggle("border-gray-500", node.dataset.certificateElement !== this.selectedId)
    })
  }

  updateSelectedInputs() {
    const element = this.findElement(this.selectedId)
    if (!element) return

    this.selectedFontFamilyTarget.value = element.font_family
    this.selectedFontSizeTarget.value = element.font_size
    this.selectedColorTarget.value = element.color
    this.selectedTextAlignTarget.value = element.text_align
    this.selectedVerticalAlignTarget.value = element.vertical_align
    this.selectedWidthTarget.value = element.width
    this.selectedHeightTarget.value = element.height
    this.selectedXTarget.value = element.x
    this.selectedYTarget.value = element.y
  }

  updateProperty(event) {
    const element = this.findElement(this.selectedId)
    if (!element) return

    const property = event.target.dataset.property
    const value = ["font_size", "width", "height", "x", "y"].includes(property) ? Number(event.target.value) : event.target.value
    element[property] = property === "x" || property === "y" ? this.clamp(value) : value
    const node = this.canvasTarget.querySelector(`[data-certificate-element="${this.selectedId}"]`)
    if (node) this.applyElementStyle(node, element)
    this.persist()
  }

  deleteSelectedElement() {
    const element = this.findElement(this.selectedId)
    if (!element) return

    if (FIXED_FIELDS[this.selectedId]) {
      this.state.element_library[this.selectedId] = element
      delete this.state[this.selectedId]
    } else if (this.selectedId.startsWith("signature-")) {
      this.state.signature_library.push(element)
      this.state.signatures = this.state.signatures.filter(signature => signature.id !== this.selectedId)
    }

    this.renderElements()
    this.renderSignatures()
    this.renderLibrary()
    this.selectBackground()
    this.persist()
  }

  restoreElement(event) {
    const id = event.currentTarget.dataset.elementId
    if (FIXED_FIELDS[id] && this.state.element_library[id]) {
      this.state[id] = this.state.element_library[id]
      delete this.state.element_library[id]
    } else {
      const signature = this.state.signature_library.find(item => item.id === id)
      if (!signature) return
      this.state.signatures.push(signature)
      this.state.signature_library = this.state.signature_library.filter(item => item.id !== id)
    }

    this.renderElements()
    this.renderSignatures()
    this.renderLibrary()
    this.selectElement(id)
    this.persist()
  }

  insertDescriptionField(event) {
    const key = event.currentTarget.dataset.fieldKey
    const input = this.descriptionInputTarget
    const token = `{{ ${key} }}`
    const start = input.selectionStart ?? input.value.length
    const end = input.selectionEnd ?? start
    input.value = `${input.value.slice(0, start)}${token}${input.value.slice(end)}`
    input.focus()
    input.setSelectionRange(start + token.length, start + token.length)
    input.dispatchEvent(new Event("input", { bubbles: true }))
  }

  addSignature() {
    this.state.signatures.push(this.normalizeElement({
      id: `signature-${Date.now()}`,
      label: `Assinatura ${this.state.signatures.length + 1}`,
      x: 50 + (this.state.signatures.length % 2) * 20,
      y: 84
    }, { width: 24, height: 10, font_size: 14 }))
    this.renderElements()
    this.renderSignatures()
    this.selectElement(this.state.signatures.at(-1).id)
    this.persist()
  }

  updateDescription() {
    const node = this.canvasTarget.querySelector('[data-certificate-element="description"]')
    if (node) node.textContent = this.descriptionPreview()
  }

  descriptionPreview() {
    return this.descriptionInputTarget.value || "Descritivo do certificado"
  }

  updateLabel(event) {
    const element = this.findElement(event.target.dataset.elementId)
    if (!element) return

    element.label = event.target.value
    const node = this.canvasTarget.querySelector(`[data-certificate-element="${element.id}"]`)
    if (node && element.id !== "verification_seal") node.textContent = element.label
    this.persist()
  }

  renderSignatures() {
    this.signatureListTarget.innerHTML = ""
    this.state.signatures.forEach(signature => this.renderLabelInput(this.signatureListTarget, signature))
  }

  renderLabelInput(container, element) {
    const label = document.createElement("label")
    label.className = "block text-sm text-gray-700 dark:text-gray-300"
    label.textContent = element.label
    const input = document.createElement("input")
    input.type = "text"
    input.value = element.label
    input.dataset.elementId = element.id
    input.dataset.action = "input->certificate-editor#updateLabel"
    input.className = "mt-1 block w-full rounded-lg border-gray-300 text-sm dark:border-gray-600 dark:bg-gray-700 dark:text-white"
    label.appendChild(input)
    container.appendChild(label)
  }

  updateBackgroundOpacity() {
    this.state.background_opacity = Number(this.backgroundOpacityTarget.value)
    this.applyBackgroundOpacity()
    this.persist()
  }

  applyBackgroundOpacity() {
    this.backgroundLayerTarget.style.opacity = this.state.background_opacity
  }

  previewBackground(event) {
    const file = event.target.files[0]
    if (!file) return

    const reader = new FileReader()
    reader.onload = () => {
      this.backgroundLayerTarget.style.backgroundImage = `url("${reader.result}")`
    }
    reader.readAsDataURL(file)
  }

  findElement(id) {
    if (FIXED_FIELDS[id]) return this.state[id]
    return this.state.signatures.find(element => element.id === id)
  }

  labelFor(id, element) {
    return FIXED_FIELDS[id] || element.label || "Elemento"
  }

  persist() {
    this.elementsTarget.value = JSON.stringify(this.state)
  }

  clamp(value) {
    return Math.max(0, Math.min(100, Math.round(Number(value) * 100) / 100))
  }
}
