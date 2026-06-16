({
    /**
     * Toggle css class on element
     * @param  {Object}  component -- Aura Component
     * @param  {String}  auraId    -- Aura Id
     * @param  {Boolean} show      -- Add or remove class
     * @param  {String}  cssClass  -- Css class to toggle ('slds-hide' by default)
     */
    toggleClass: function(component, auraId, show, cssClass) {
        cssClass = cssClass ? cssClass : 'slds-hide';
        if(show) {
            $A.util.removeClass(component.find(auraId), cssClass);
        } else {
            $A.util.addClass(component.find(auraId), cssClass);
        }
    },
    /**
     * Position the popover
     * @param component
     * @param target             -- reference to the element that need to have a popover
     * @param preferredPosition  -- top, right, bottom, left
     */
    setPosition: function(component, target, preferredPosition){
        function isNumeric(n) {
            return !isNaN(parseFloat(n)) && isFinite(n);
        }
        var popover = component.find('popover').getElement();
        var popoverRect = popover.getBoundingClientRect();
        var targetRect = target.getBoundingClientRect();
        var containerRect = popover.parentNode.getBoundingClientRect();
        var top;
        var left;
        var nubbin = 11; // Nubbin width [px]
        var nubbinMargin = 25; // Space from the edge to the nubbin [px]
        var popoverWidth = popoverRect.width + nubbin;
        var popoverHeight = popoverRect.height + nubbin;
        var style = '';

        /**
         *  1) Check Space around target if popover will fit
         */

        // Enough space on the right
        var isRightOk = (containerRect.right - targetRect.right) > popoverWidth ;

        // Enough space on the left
        var isLeftOk = (containerRect.left - targetRect.left) > popoverWidth;

        // Enough space on the top
        var isTopOk = (targetRect.top - containerRect.top) > popoverHeight;

        // Enough space on the bottom
        var isBottomOk = (containerRect.bottom - targetRect.bottom) > popoverHeight;

        // Enough space if popover is on the middle of the top/bottom side of the target
        var ishMiddleOk = ((targetRect.left - containerRect.left) > (popoverRect.width - targetRect.width ) / 2) &&
                          ((containerRect.right - targetRect.right) > (popoverRect.width - targetRect.width) / 2);

        // Enough space if popover is shifted to the Right
        var ishRightOk = (containerRect.right - targetRect.right) > (popoverRect.width - targetRect.width);

        // Enough space if popover is on the middle of the side of the target
        var isvMiddleOk = ((targetRect.top - containerRect.top) > (popoverRect.height - targetRect.height) / 2) &&
                          ((containerRect.bottom - targetRect.bottom) > (popoverRect.height - targetRect.height) / 2);

        // Enough space if popover is shifted to the Top
        var isvTopOk = (targetRect.top - containerRect.top) > (popoverRect.height - targetRect.height);

        /**
         *  2) Decide where to put popover and calculate its position
         */
        var nubbinPosition;

        // Center popover vertically related to target
        var vMiddle = targetRect.bottom - containerRect.top - (targetRect.height / 2) - (popoverRect.height / 2);
        var vTop = targetRect.bottom - containerRect.top - (targetRect.height / 2) - popoverRect.height + nubbinMargin;
        var vBottom = targetRect.bottom - containerRect.top - (targetRect.height / 2) - nubbinMargin;

        // Center popover horizontally related to target
        var hMiddle = targetRect.right - (targetRect.width / 2) - (popoverRect.width / 2);
        var hRight = targetRect.right - containerRect.left - (targetRect.width / 2) - nubbinMargin;
        var hLeft = targetRect.right - containerRect.left - (targetRect.width / 2) - popoverRect.width + nubbinMargin;

        function position(prefPosition) {
            if (isRightOk && (prefPosition === 'right' || !prefPosition)) {
                // Place popover on the right from target
                left = targetRect.right - containerRect.left + nubbin;
                nubbinPosition = 'left';
                if (isvMiddleOk) {
                    // Popover in the middle
                    top = vMiddle;
                } else if (isvTopOk) {
                    // Shift Popover to the top
                    top = vTop;
                    nubbinPosition += '-bottom';
                } else {
                    // Shift Popover to the bottom
                    top = vBottom;
                    nubbinPosition += '-top';
                }

            } else if (isLeftOk && (prefPosition === 'left' || !prefPosition)) {
                // Place popover on the left from target
                left = targetRect.left - containerRect.left - popover.right - nubbin;
                nubbinPosition = 'right';
                if (isvMiddleOk) {
                    // Popover in the middle
                    top = vMiddle;
                } else if (isvTopOk) {
                    // Shift Popover to the top
                    top = vTop;
                    nubbinPosition += '-bottom';
                } else {
                    // Shift Popover to the bottom
                    top = vBottom;
                    nubbinPosition += '-top';
                }

            } else if (isTopOk && (prefPosition === 'top' || !prefPosition)) {
                // Place popover on the top from target.
                top = targetRect.top - containerRect.top - popoverRect.height - nubbin - window.scrollY;
                nubbinPosition = 'bottom';
                if (ishMiddleOk) {
                    // Popover in the middle
                    left = hMiddle;
                } else if (ishRightOk) {
                    // Shift Popover to the right
                    left = hRight;
                    nubbinPosition += '-left';
                } else {
                    // Shift Popover to the left
                    left = hLeft;
                    nubbinPosition += '-right';
                }

            } else if (isBottomOk && (prefPosition === 'bottom' || !prefPosition)) {
                // Place popover on the bottom from target.
                top = targetRect.bottom - containerRect.top + nubbin - window.scrollY;
                nubbinPosition = 'top';
                if (ishMiddleOk) {
                    // Popover in the middle
                    left = hMiddle;
                } else if (ishRightOk) {
                    // Shift Popover to the right
                    left = hRight;
                    nubbinPosition += '-left';
                } else {
                    // Shift Popover to the left
                    left = hLeft;
                    nubbinPosition += '-right';
                }

            }
        }

        position(preferredPosition);
        // If it is not possible to place popover on preferred position, place it automatically
        if (!isNumeric(top) && !isNumeric(left) && preferredPosition){
            position();
        }

        // 3) Convert position to css styles

        if (isNumeric(top)) {
            style += 'top:' + top + 'px;';
        }
        if (isNumeric(left)) {
            style += 'left:' + left + 'px;';
        }

        // 4) Apply changes
        component.set('v.style', style);
        component.set('v.nubbinPosition', nubbinPosition);
    },
    setTheme: function(component, theme){
        var themeClass = '';
        if (theme === 'tooltip'){
            themeClass="slds-popover_tooltip";
        } else if (theme){
            themeClass="slds-theme--"+theme;
        }
        component.set('v.themeClass',themeClass);
    }
})