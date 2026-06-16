({
    rating: function(el, currentRating, maxRating) {
        let stars = [];
        (function init() {
            for (let i = 0; i < maxRating; i++) {
                let star = document.createElement('li');
                star.classList.add('c-rating__item');
                star.setAttribute('data-index', i);
                if (i < currentRating) { 
                    star.classList.add('is-active'); 
                }
                el.appendChild(star);
                stars.push(star);
            }
        })();
    }
})