import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select";


// Connects to data-controller="tom-select"
export default class extends Controller {
  static targets = ["select"]

  connect() {
    new TomSelect(this.selectTarget,{
      allowEmptyOption: true,
    });
  }
}
