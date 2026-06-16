(function(win, doc){
  var hasTouchEvents = ('ontouchstart' in window)

  var assign = Object.assign || objectAssign
  var utils = win.LC = {
    initSidebarToggler: initSidebarToggler,
    addClass: addClass,
    removeClass: removeClass,
    toggleClass: toggleClass,
    elem: elem,
    appendTo: appendTo,
    assign: assign,
    debounce: debounce,
    throttle: throttle,
  }

  return

  ////////////////////

  function initSidebarToggler() {
    var page = doc.querySelector('.page')
    var trigger = doc.querySelector('.page__sidebar-trigger')
    var overlay = doc.querySelector('.page__inner-overlay')
    if (hasTouchEvents) {
      trigger.addEventListener('touchstart', handleTriggerClick)
      overlay.addEventListener('touchstart', handleTriggerClick)
    } else {
      trigger.addEventListener('click', handleTriggerClick)
      overlay.addEventListener('click', handleTriggerClick)
    }

    function handleTriggerClick(evt) {
      evt.preventDefault()
      evt.stopPropagation()
      toggleClass(page, 'page--menu-open')
    }
  }

  // Utils

  function objectAssign(target) {
    'use strict';
    if (target == null) {
      throw new TypeError('Cannot convert undefined or null to object');
    }
    target = Object(target);
    for (var index = 1; index < arguments.length; index++) {
      var source = arguments[index];
      if (source != null) {
        for (var key in source) {
          if (Object.prototype.hasOwnProperty.call(source, key)) {
            target[key] = source[key];
          }
        }
      }
    }
    return target;
  }

  function throttle(func, ms) {
    var isThrottled = false
    var savedArgs
    var savedThis
    function wrapper() {
      if (isThrottled) {
        savedArgs = arguments
        savedThis = this
        return
      }
      func.apply(this, arguments)
      isThrottled = true
      setTimeout(function() {
        isThrottled = false
        if (savedArgs) {
          wrapper.apply(savedThis, savedArgs)
          savedArgs = savedThis = null
        }
      }, ms)
    }
    return wrapper
  }

  function debounce(func, wait, immediate) {
    var timeout
    return function() {
      var context = this
      var args = arguments
      var later = function() {
        timeout = null
        if ( !immediate ) {
          func.apply(context, args)
        }
      }
      var callNow = immediate && !timeout
      clearTimeout(timeout)
      timeout = setTimeout(later, wait || 200)
      if ( callNow ) {
        func.apply(context, args)
      }
    }
  }


  function addClass(el, className) {
    var classNames = el.className.split(' ')
    if (classNames.indexOf(className) === -1) {
      el.className = el.className + ' ' + className
    }
  }

  function removeClass(el, className) {
    var classNames = el.className.split(' ')
    el.className = classNames.filter(not(equals(className))).join(' ')
  }

  function toggleClass(el, className) {
    var classNames = el.className.split(' ')
    if (classNames.indexOf(className) === -1) {
      el.className = el.className + ' ' + className
    } else {
      el.className = classNames.filter(not(equals(className))).join(' ')
    }
  }


  function elem(tag, props, children) {
    var el = document.createElement(tag)
    for (var prop in props) {
      if(props.hasOwnProperty(prop)) {
        if (prop === 'style') {
          assign(el.style, props[prop])
        } else {
          el[prop] = props[prop]
        }
      }
    }
    appendTo(el, children)
    return el
  }


  function appendTo(el, children) {
    if (children) {
      if (Array.isArray(children)) {
        children.forEach(function(child) {
          appendTo(el, child)
        })
      } else {
        if (typeof children === 'string') {
          children = document.createTextNode(children)
        }
        el.appendChild(children)
      }
    }
  }

  function equals(a) {
    return function(b) { return a === b }
  }

  function not(fn) {
    return function() { return !fn.apply(null, arguments) }
  }


})(window, document)
