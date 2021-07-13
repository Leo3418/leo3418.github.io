$(document).ready(function () {
    $(".lang-switcher-toggle").click(function () {
        $(this).toggleClass("close");
    });

    $("nav > button").click(function () {
        var shouldOpenMenu = $(this).hasClass("close");
        if (shouldOpenMenu) {
            // Ensure all other menus are closed
            $("nav > button").removeClass("close");
            $("nav > button + ul").addClass("hidden");
            // Open the menu toggled by this button
            $(this).addClass("close");
            $(this).next().removeClass("hidden");
        } else {
            $(this).removeClass("close");
            $(this).next().addClass("hidden");
        }
    });
});
