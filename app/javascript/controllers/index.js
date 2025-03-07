// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
import OrderFormController from "./orders/order_form_controller"
eagerLoadControllersFrom("controllers", application)
application.register("order-form", OrderFormController)
