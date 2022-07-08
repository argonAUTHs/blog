$(window).load(function() {

  $('.nav_slide_button').click(function() {
    $('.pull').slideToggle({
        "easing:": "easeInCubic",
        complete: function() {
          $("ul.top-nav").fadeToggle({duration: 300});
        }
    });
  });
});