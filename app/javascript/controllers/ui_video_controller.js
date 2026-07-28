import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="ui-video"
export default class extends Controller {
  connect() {
    const videoTarget = this.element.matches("video") ? this.element : document.querySelector('#my-player')
    if (!videoTarget || !window.videojs) return

    videoTarget.classList.add('video-js')
    const video = videoTarget.player || window.videojs(videoTarget, {
        controls: true,
        disablePictureInPicture: true,
        autoplay: false,
        disablePictureInPicture: true,
        preload: 'auto',
        fluid: true
    })

    video.on('ended', () => {
      const completeUrl = videoTarget.dataset.completeUrl
      if (completeUrl) {
        fetch(completeUrl, {
          method: 'POST',
          headers: {
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
            'Accept': 'application/json'
          }
        }).then(response => response.json()).then(data => {
          if (data.certificate_ready) document.querySelector('[data-certificate-download]')?.classList.remove('hidden')
        })
      }

      const nextCourseClass = document.querySelector('.course-class-active + li a')
      if (nextCourseClass) nextCourseClass.click()
    })
  }
}
