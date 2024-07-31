import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="ui-dark-mode"
export default class extends Controller {
  connect() {
    this.colorTheme()
  }

  colorTheme() {
    const themeToggleDarkIcon = document.getElementById('theme-toggle-dark-icon');
    const themeToggleLightIcon = document.getElementById('theme-toggle-light-icon');
    const htmlTarget = document.querySelector('html');

    // Change the icons inside the button based on previous settings
    if (localStorage.getItem('color-theme') === 'dark' || (!('color-theme' in localStorage) && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
      htmlTarget.classList.add('dark')

      if(!themeToggleLightIcon) return;
    
      themeToggleLightIcon.classList.remove('hidden');
    } else {
      htmlTarget.classList.remove('dark')

      if(!themeToggleDarkIcon) return;
      
      themeToggleDarkIcon.classList.remove('hidden');
    }

    const themeToggleBtn = document.getElementById('theme-toggle');

    let event = new Event('dark-mode');

    themeToggleBtn.addEventListener('click', function () {

      // toggle icons
      themeToggleDarkIcon.classList.toggle('hidden');
      themeToggleLightIcon.classList.toggle('hidden');

      // if set via local storage previously
      if (localStorage.getItem('color-theme')) {
        if (localStorage.getItem('color-theme') === 'light') {
          document.documentElement.classList.add('dark');
          localStorage.setItem('color-theme', 'dark');
        } else {
          document.documentElement.classList.remove('dark');
          localStorage.setItem('color-theme', 'light');
        }

        // if NOT set via local storage previously
      } else {
        if (document.documentElement.classList.contains('dark')) {
          document.documentElement.classList.remove('dark');
          localStorage.setItem('color-theme', 'light');
        } else {
          document.documentElement.classList.add('dark');
          localStorage.setItem('color-theme', 'dark');
        }
      }

      document.dispatchEvent(event);

    });
  }
}
