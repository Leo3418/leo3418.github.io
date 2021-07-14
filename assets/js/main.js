$(document).ready(function () {
    $(".lang-switcher-toggle").click(function () {
        $(this).toggleClass("close");
    });

    $("#site-nav > button").click(function () {
        var shouldOpenMenu = $(this).hasClass("close");
        if (shouldOpenMenu) {
            // Ensure all other menus are closed
            $("#site-nav > button").removeClass("close");
            $("#site-nav > button + ul").addClass("hidden");
            // Open the menu toggled by this button
            $(this).addClass("close");
            $(this).next().removeClass("hidden");
        } else {
            $(this).removeClass("close");
            $(this).next().addClass("hidden");
        }
    });
});
