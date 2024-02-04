document.addEventListener("DOMContentLoaded", function(event) {
  var slides = document.querySelectorAll(".slide");
  var currentSlide = 0;

  // Show the first slide
  slides[currentSlide].style.display = "block";

  // Play the audio
  const audio = document.getElementById('audioPlayer');
  const playButton = document.getElementById('playButton');

  playButton.addEventListener('click', function() {
    audio.play();
  });

  // Define function to show next slide
  function showNextSlide() {
    slides[currentSlide].style.display = "none"; // Hide current slide
    currentSlide = (currentSlide + 1) % slides.length; // Increment current slide index
    slides[currentSlide].style.display = "block"; // Show next slide
  }

  // Set interval to automatically show next slide every 3 seconds
  setInterval(showNextSlide, 3000);
});