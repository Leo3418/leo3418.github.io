// Make navigation menus mutually exclusive
(function () {
    const toggles = document.getElementsByClassName("nav-toggle");
    for (const toggle of toggles) {
        toggle.addEventListener("click", function () {
            const tmp = toggle.checked;
            for (const t of toggles) {
                t.checked = false;
            }
            toggle.checked = tmp;
        });
    }
})();
