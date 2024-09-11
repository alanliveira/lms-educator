import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="ui-video"
export default class extends Controller {
  connect() {
    // var video = document.getElementById('my-player_html5_api');
    while (true) {
      const videoTarget = document.querySelector('#my-player')
      if (!videoTarget) continue
      videoTarget.classList.add('video-js')

      const video = window.videojs(videoTarget, {
        controls: true,
        autoplay: false,
        preload: 'auto',
        fluid: true
      })

      video.on('ended', function () {
        // alert("O vídeo terminou.");

        const learnActive = document.querySelector('.course-class-active')
        const [element, courseStep] = learnActive.id.split('course_class_')
        const nextStepCourseClass = parseInt(courseStep) + 1
        const nextCourseClass = document.querySelector(`#course_class_${nextStepCourseClass}`)

        if (!!nextCourseClass) {
          nextCourseClass.click()
        } // else {
        //   alert('Acabou o curso')
        // }
      });

      break;
    }
  }
}
