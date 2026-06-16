/**
 * Created on 18.10.2018
 */
({
    timer: null,
    touchstartCoordX: null,
    touchendCoordX: null,
    touchstartCoordY: null,
    touchendCoordY: null,
    autoscroll: false,
    update: function update(cmp) {},
    bodyTouchstart: function bodyTouchstart(event, cmp) {
        var touchstartCoordX = event.changedTouches[0].clientX;
        var touchstartCoordY = event.changedTouches[0].clientY;
        this.touchstartCoordX = touchstartCoordX;
        this.touchstartCoordY = touchstartCoordY;
        // event.preventDefault();
    },
    bodyTouchmove: function bodyTouchmove(event, cmp) {
        var CoordX = event.changedTouches[0].clientX;
        var CoordY = event.changedTouches[0].clientY;

        // event.preventDefault();
        var changeX = Math.abs(CoordX - this.touchstartCoordX);
        var changeY = Math.abs(CoordY - this.touchstartCoordY);
        if(changeX > 30)
            event.preventDefault()
    },
    bodyTouchend: function bodyTouchend(event, cmp) {
        if (this.touchstartCoordX) {
            this.touchendCoordX = event.changedTouches[0].clientX;
            this.touchendCoordY = event.changedTouches[0].clientY;
            var direction = this.touchendCoordX < this.touchstartCoordX ? 'left' : 'right';
            var changeX = Math.abs(this.touchendCoordX - this.touchstartCoordX);
            var changeY = Math.abs(this.touchendCoordY - this.touchstartCoordY);
            if (changeX > 30 && changeY < 50) {

                var current = cmp.get("v.active");
                var count = cmp.get("v.count");
                if (direction === 'right') {
                    current--;
                } else {
                    current++;
                }
                event.preventDefault();
                if (current < 0) current = count - 1;
                if (current === count) current = 0;
                cmp.set("v.active", current);
                this.nextSlide(cmp);
            }
        }
    },
    nextSlide: function nextSlide(cmp) {
        var _this = this;
        clearTimeout(this.timer);
        var current = cmp.get("v.active");
        var count = cmp.get("v.count");
        var duration = cmp.get("v.scrollDuration") || 5;
        current++;
        if (current === count) current = 0;
        if(this.autoscroll)
            this.timer = setTimeout(function () {
                cmp.set("v.active", current);
                _this.nextSlide(cmp);
            }, duration * 1000);
    },
    dotClick: function dotClick(cmp, element) {
        var current = element.getAttribute('tabindex') * 1;
        cmp.set("v.active", current);
        this.nextSlide(cmp);
    },
    swipeSlide: function swipeSlide(cmp) {
        this.cmp = cmp;
        var whoIAm = cmp.get('v.whoIAm');
        var elMain = document.querySelector('.cSupportCommunitySlider.' + whoIAm + ' .slds-carousel__panels');
        if (elMain) {
            // elMain.addEventListener('touchstart', this.bodyTouchstart, false);
            // elMain.addEventListener('touchend', this.bodyTouchend, false);
        }
    }
});