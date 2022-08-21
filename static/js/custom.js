// Make navigation menus mutually exclusive
$(".nav-toggle").click(function () {
    var tmp = $(this).prop("checked");
    $(".nav-toggle").prop("checked", false);
    $(this).prop("checked", tmp);
});
