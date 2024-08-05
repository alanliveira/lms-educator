import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="ui-sidebar"
export default class extends Controller {
  connect() {
    const sidebar = document.getElementById('sidebar');

    if (sidebar) {
      const toggleSidebarMobile = (sidebar, sidebarBackdrop, toggleSidebarMobileHamburger, toggleSidebarMobileClose) => {
        sidebar.classList.toggle('hidden');
        sidebarBackdrop.classList.toggle('hidden');
        toggleSidebarMobileHamburger.classList.toggle('hidden');
        toggleSidebarMobileClose.classList.toggle('hidden');
      }

      const toggleSidebarMobileEl = document.getElementById('toggleSidebarMobile');
      const sidebarBackdrop = document.getElementById('sidebarBackdrop');
      const toggleSidebarMobileHamburger = document.getElementById('toggleSidebarMobileHamburger');
      const toggleSidebarMobileClose = document.getElementById('toggleSidebarMobileClose');
      const toggleSidebarMobileSearch = document.getElementById('toggleSidebarMobileSearch');

      toggleSidebarMobileSearch.addEventListener('click', () => {
        toggleSidebarMobile(sidebar, sidebarBackdrop, toggleSidebarMobileHamburger, toggleSidebarMobileClose);
      });

      toggleSidebarMobileEl.addEventListener('click', () => {
        toggleSidebarMobile(sidebar, sidebarBackdrop, toggleSidebarMobileHamburger, toggleSidebarMobileClose);
      });

      sidebarBackdrop.addEventListener('click', () => {
        toggleSidebarMobile(sidebar, sidebarBackdrop, toggleSidebarMobileHamburger, toggleSidebarMobileClose);
      });
    }
  }
}
