import { Controller } from "@hotwired/stimulus"
import { Dismiss } from 'flowbite';

// Connects to data-controller="ui-toast-notification"
export default class extends Controller {
  close(event) {
    // target element that will be dismissed
    const $targetEl = document.getElementById('toast-notification');

    // optional trigger element
    const $triggerEl = document.getElementById('trigger-notification');

    // options object
    const options = {
      transition: 'transition-opacity',
      duration: 1000,
      timing: 'ease-out',

      // callback functions
      onHide: (context, targetEl) => {
        console.log('element has been dismissed')
        console.log(targetEl)
      }
    };

    // instance options object
    const instanceOptions = {
      id: 'targetElement',
      override: true
    };

    const dismiss = new Dismiss($targetEl, $triggerEl, options, instanceOptions);
    dismiss.hide()
  }
}
