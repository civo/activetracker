$(function() {
  $(".js-activetracker-tab").click(function() {
    var $this = $(this);
    $this.siblings(".js-activetracker-tab").removeClass("text-blue-600").addClass("text-gray-500");
    $this.addClass("text-blue-600").removeClass("text-gray-500");

    targetTabName = $(this).data("tab");
    var $targetTab = $(".js-activetracker-tab-content").filter('[data-content="' + targetTabName + '"]');
    $targetTab.removeClass("hidden");
    $targetTab.siblings(".js-activetracker-tab-content").addClass("hidden");
  });
});
