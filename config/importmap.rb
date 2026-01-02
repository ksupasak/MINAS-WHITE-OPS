pin "application", preload: true

pin "controllers", to: "controllers/index.js", preload: true

pin "@hotwired/turbo-rails", to: "https://cdn.jsdelivr.net/npm/@hotwired/turbo@8.0.0/dist/turbo.es2017-umd.js", preload: true
pin "@hotwired/stimulus", to: "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/dist/stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "https://cdn.jsdelivr.net/npm/@hotwired/stimulus-loading@1.0.0/dist/stimulus-loading.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"
pin "cytoscape", to: "https://unpkg.com/cytoscape@3.29.2/dist/cytoscape.esm.min.js"
