({
    items: null,
    len: 1,
    disp: 4,
    item_w: 240,
    animate: false,
    dots: 1,
    currentView: 'desktop',
    min_padd: { desktop: 15, tablet: 12.75, mobile: 9.25 },
    padd: 15,
    item_w_m: 240,
    playTimer: null,
    playInterval: 5000,
    speed: 500,
    cmp: null,
    autoscroll: false,

    getCurrentView: function getCurrentView() {
        var w = $(window).width();
        if (w > 768) return 'desktop';else if (w > 740) return 'tablet';else return 'mobile';
    },
    init: function init(cmp, itLen) {
        var _this2 = this;

        this.cmp = cmp;
        this.itLen = itLen;
        this.animate = false;
        this.autoscroll = cmp.get('v.param_anim');
        this.playInterval = cmp.get('v.param_pInterval');
        this.speed = cmp.get('v.param_speed');
        this.min_padd.desktop = cmp.get('v.param_mpDesktop');
        this.min_padd.tablet = cmp.get('v.param_mpTablet');
        this.min_padd.mobile = cmp.get('v.param_mpMobile');
        this.currentView = this.getCurrentView();
        // console.log("resize",this.currentView,$(window).width());
        $(".carousel_place .loader").show();
        this.items = $(".carousel__item");
        if (this.items.length === 0 && itLen > 0) {
            //console.warn("Carousel load early... try again");
            setTimeout(function () {
                _this2.init(cmp, itLen);
            }, 300);
            return null;
        }
        this.len = this.items.filter('[data-origin="true"]').length;
        var csel = $(".carousel_place .carousel__view");
        if (this.len === this.items.length) $('.carousel__items').prepend(this.items.clone().attr('data-origin', 'false')).append(this.items.clone().attr('data-origin', 'false'));
        // $('.carousel__item').click(function () {
        //     window.open($(this).attr('data-link'), '_blank');
        // });
        if (csel.data('inited') !== true) {
            csel.on('touchstart', function (event) {
                // console.log(event.originalEvent);
                // event.preventDefault();
                var touchstartCoordX = event.originalEvent.changedTouches[0].clientX;
                var touchstartCoordY = event.originalEvent.changedTouches[0].clientY;
                $(event.currentTarget).data('touchstartCoordX', touchstartCoordX);
                $(event.currentTarget).data('touchstartCoordY', touchstartCoordY);
                var elMainCoordX0 = $(event.currentTarget)[0].getBoundingClientRect().left;
                $(event.currentTarget).data('elMainCoordX0', elMainCoordX0);
            });
            csel.on('touchmove', function (event) {
                event.preventDefault();
                var touchmoveCoordX = event.originalEvent.changedTouches[0].clientX;
            });
            csel.on('touchend', function (event) {
                //event.preventDefault();
                var touchendCoordX = event.originalEvent.changedTouches[0].clientX;
                var touchendCoordY = event.originalEvent.changedTouches[0].clientY;
                var touchstartCoordX = $(event.currentTarget).data('touchstartCoordX');
                var touchstartCoordY = $(event.currentTarget).data('touchstartCoordY');
                var direction = touchendCoordX < touchstartCoordX ? 'left' : 'right';
                var changeX = Math.abs(touchendCoordX - touchstartCoordX);
                var changeY = Math.abs(touchendCoordY - touchstartCoordY);
                if (changeX > 30 && changeY < 50) {
                    if (direction === 'left') _this2.right();else _this2.left();
                }
            });
            csel.data('inited', true);
        }
        var block = $('.carousel__item .item__block');
        if(block.length === 0) {
            console.error("Carousel haven't items");
            return null;}
        this.item_w = block[0].clientWidth;
        var w = this.item_w + this.min_padd[this.currentView] * 2;
        var carousel_w = csel[0].clientWidth;
        if (carousel_w < w) {
            $(".carousel_place").hide();
            console.error("Carousel min width: ", w, ", Now:", carousel_w, " Please resize window to show carousel!");
        } else {
            $(".carousel_place").show();

            this.disp = Math.floor((carousel_w + this.min_padd[this.currentView] * 2) / w);
            if (this.disp > this.len) this.disp = this.len;
            if (this.disp > 1) {
                this.padd = (carousel_w - this.item_w * this.disp) / ((this.disp - 1) * 2);
                $('.carousel__items').css("left", (this.len * (this.item_w + this.padd * 2) + this.padd) * -1 + "px");
            } else {
                this.padd = (carousel_w - this.item_w) / 2;
                $('.carousel__items').css("left", this.len * (this.item_w + this.padd * 2) * -1 + "px");
            }
            $('.carousel__item').css("padding-left", this.padd + "px").css("padding-right", this.padd + "px");
            this.dots = this.len;
            this.item_w_m = this.padd * 2 + this.item_w;
            var dotList = [];
            for (var i = 1; i <= this.dots; i++) {
                dotList.push({
                    value: i
                });
            }
            cmp.set("v.dots", dotList);
            $(".carousel_place .loader").hide();
            this.changeActiveDot();
            this.play();
        }
    },
    play: function play() {
        if(this.autoscroll) {
            var _this3 = this;
            clearTimeout(_this3.playTimer);
            this.playTimer = setTimeout(function () {
                _this3.right();
            }, _this3.playInterval);
        }
    },
    dotClick: function dotClick(inx) {
        console.log("dotClick", inx);
        this.orderByItem(inx);
        this.play();
    },
    changeActiveDot: function changeActiveDot() {
        var fist = jQuery(".carousel__item:nth-child(" + (this.len + 1) + ")");
        var id = fist.attr("data-id") * 1 - 1;
        this.cmp.set("v.active_dot", id);
    },
    orderByItem: function orderByItem(index) {
        //Go to item
        index = index + 1;
        var first = $(".carousel__item:nth-child(" + (this.len + 1) + ")");
        var first_id = first.attr("data-id") * 1;
        if (index !== first_id) {
            var to_left = 0;
            var to_right = 0;
            var b = 0;
            if (first_id < index) {
                b = index - this.len;
                to_left = first_id + b * -1;
                to_right = index - first_id;
            } else {
                to_left = first_id - index;
                b = this.len + index;
                to_right = b - first_id;
            }
            //console.log('from: ',first_id,'to: ',index, 'to_left: ',to_left,'to_right: ', to_right);
            if (to_right < to_left) {
                this.right(Math.floor(this.speed / to_right), to_right);
            } else {
                this.left(Math.floor(this.speed / to_left), to_left);
            }
        }
    },
    left: function left(force_speed, count) {
        var _this4 = this;

        if (force_speed === undefined) {
            force_speed = this.speed;
            count = 1;
        }
        if (!this.animate) {
            this.animate = true;
            this.items.each(function (inx, val) {
                var o = $(val).attr("data-order") * 1;
                o = o + 1;
                if (o > _this4.len) o = 1;
                $(val).attr("data-order", o);
            });

            var last = $(".carousel__item:last-child");

            var _this = this;
            last.clone().css("margin-left", this.item_w_m * -1 + "px").prependTo(".carousel__items").animate({
                marginLeft: 0
            }, force_speed, function () {
                $(this).css("margin-left", 0);
                _this.animate = false;
                _this.play();
                if (count > 1) _this.left(force_speed, --count);
            });
            this.changeActiveDot();
            last.remove();
        }
    },
    right: function right(force_speed, count) {
        if (force_speed === undefined) {
            force_speed = this.speed;
            count = 1;
        }
        if (!this.animate) {
            this.animate = true;
            var first = $(".carousel__item:first-child");
            var _this = this;
            var current_w = $('.carousel__item .item__block')[0].clientWidth;
            first.animate({
                marginLeft: "-=" + this.item_w_m
            }, force_speed, function () {
                _this.animate = false;
                $(this).clone().css('margin-left', '0').appendTo(".carousel__items");
                $(this).remove();
                _this.changeActiveDot();
                _this.play();
                if (count > 1) _this.right(force_speed, --count);
            });
        }
    },
    initItems: function(cmp) {
        var action = cmp.get("c.getPictures");
        // var domain = '';
        // if (window.app !== undefined && window.app != null && window.app.contentDomain != undefined) domain = window.app.contentDomain;
        // else return 0;
        action.setParams({ place: "carousel", country: window.app.language });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var items = response.getReturnValue();
                items = items.filter(function (item) {
                    return item.Image__c !== null;
                });
                cmp.set("v.carouselItems", items);
                this.init(cmp, items.length);
            } else {
                console.error("Failed with state: " + state);
            }
        });
        $A.enqueueAction(action);
    },
    doInitJQ: function doInitJQ(cmp) {
        if(window && window.app && window.app.language) {
            cmp.set('v.first_init',false);
            this.initItems(cmp);
            var this_ = this;
            jQuery(window).resize(function () {
                this_.init(cmp);
            });
            window.addEventListener("orientationchange", function () {
                this_.init(cmp);
            }, false);
        }
    },
});