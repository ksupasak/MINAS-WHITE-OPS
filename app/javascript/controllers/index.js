import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
import controllers from "controllers"

eagerLoadControllersFrom("controllers", application)
