import { Controller } from "@hotwired/stimulus"
import cytoscape from "cytoscape"

export default class extends Controller {
  static values = {
    dataUrl: String
  }

  connect() {
    this.fetchAndRender()
  }

  async fetchAndRender() {
    if (!this.dataUrlValue) return
    const response = await fetch(this.dataUrlValue)
    if (!response.ok) return
    const payload = await response.json()
    this.renderGraph(payload)
  }

  renderGraph(payload) {
    const container = this.element
    const nodes = payload.nodes?.map((node) => ({ data: node })) || []
    const edges = payload.edges?.map((edge) => ({ data: edge })) || []

    cytoscape({
      container,
      elements: [...nodes, ...edges],
      style: [
        {
          selector: "node",
          style: {
            label: "data(label)",
            "background-color": "#0d6efd",
            color: "#fff",
            "text-valign": "center",
            "text-halign": "center",
            "font-size": 10
          }
        },
        {
          selector: "edge",
          style: {
            width: 2,
            "line-color": "#adb5bd",
            "curve-style": "bezier",
            "target-arrow-shape": "triangle",
            "target-arrow-color": "#adb5bd"
          }
        }
      ],
      layout: { name: "cose", padding: 20 }
    })
  }
}
