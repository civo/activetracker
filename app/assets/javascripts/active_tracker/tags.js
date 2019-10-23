$(function() {
  $(".js-tags span").click(function(e) {
    var $this = $(this);

    var tag = $this.text();
    var $input = $(".js-filter-form .js-filter-input");
    if (!$input.val().includes(tag)) {
      if ($input.val().length > 0) {
        $input.val($input.val() + " ");
      }
      $input.val($input.val() + tag);
      $(".js-filter-form").submit();
    }

    e.preventDefault();
    return false;
  });
});
