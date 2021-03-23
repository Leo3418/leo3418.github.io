$(document).ready(function () {
    // Language switcher toggle
    $(".lang-switcher-toggle").on("click", function () {
        $(".lang-switcher").toggleClass("hidden");
        // Hide navigation menu when language switcher is open
        $(".hidden-links").addClass("hidden");
    });

    // Hide language switcher when navigation menu is open
    $(".greedy-nav__toggle").on("click", function () {
        $(".lang-switcher").addClass("hidden");
    });
});
