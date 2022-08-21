$(function() {
    // Gumshoe scroll spy init
    if($("nav.toc").length > 0) {
        var spy = new Gumshoe("nav.toc a", {
            // Active classes
            navClass: "active", // applied to the nav list item
            contentClass: "active", // applied to the content

            // Nested navigation
            nested: false, // if true, add classes to parents of active link
            nestedClass: "active", // applied to the parent items

            // Offset & reflow
            offset: 20, // how far from the top of the page to activate a content area
            reflow: true, // if true, listen for reflows

            // Event support
            events: true // if true, emit custom events
        });
    }
})
