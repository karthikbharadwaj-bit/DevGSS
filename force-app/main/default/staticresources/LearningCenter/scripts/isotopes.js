(function(win, doc, LC) {

  LC.initIsotopes = initIsotopes
  LC.createIsotopes = createIsotopes
  var forEach = Array.prototype.forEach

  return

  ////////////////////

  function initIsotopes(selector) {
    var isotopesContainers = doc.querySelectorAll(selector || '.js-isotopes')
    forEach.call(isotopesContainers, createIsotopes)
  }

  function createIsotopes(container) {
    var ISOTOPE_OVERLAP = 90
    var isotopes = container.querySelectorAll('.isotope')
    if (isotopes.length !== 6) {
      return
    }
    var isActive = false
    var isotopesSizes = []
    var columnsCount
    var maxHeight
    var newIsotopeHeight
    var halfHeight
    var unsubscribers = []

    function unbindEvents() {
      unsubscribers.forEach(function (unsubscribe) {
        unsubscribe()
      })
      unsubscribers = []
    }

    if (window.innerWidth > 800) {
      setTimeout(activate, 200)
    }

    // setTimeout(updateLayout, 5000)

    window.addEventListener('resize', activate, false)

    function activate() {
      if (window.innerWidth >= 800) {
        updateLayout()
        if (!isActive) {
          bindEvents()
          var images = container.querySelectorAll('img')
          forEach.call(images, function(img) {
            img.addEventListener('load', updateLayout)
          })
        }
        isActive = true

      } else {
        resetStyles()
        if (isActive) {
          unbindEvents()
        }
        isActive = false
      }
    }

    return

    //////////////////////////

    function updateLayout() {
      resetStyles()
      calculateDimensions()
      applySizes()
    }

    function calculateDimensions() {
      container.style.position = 'relative'
      columnsCount = getColumnsCount(isotopes)
      maxHeight = getMaxHeight(isotopes)
      newIsotopeHeight = maxHeight + ISOTOPE_OVERLAP
      halfHeight = newIsotopeHeight / 2
      isotopesSizes = []

      forEach.call(isotopes, function(el, idx, list) {
        var row = (idx < columnsCount) ? 0 : 1
        var width = el.offsetWidth
        var left = el.offsetLeft
        isotopesSizes.push([
          width,
          halfHeight,
          left,
          (row * halfHeight),
        ])
      })
    }

    function applySizes() {
      container.style.height = newIsotopeHeight + 'px'
      container.style.position = 'relative'
      isotopesSizes.forEach(function(a, idx) {
        var el = isotopes[idx]
        el.style.transition = ''
        el.style.position = 'absolute'
        el.style.width = a[0] + 'px'
        el.style.height = a[1] + 'px'
        el.style.left = a[2] + 'px'
        el.style.top = a[3] + 'px'
      })
    }

    function bindEvents() {
      forEach.call(isotopes, function (el, idx, list) {
        var supplementingIsotopeIdx = (idx + columnsCount) % list.length
        var supplementingIsotopeRow = (supplementingIsotopeIdx < columnsCount) ? 0 : 1
        var supplementingIsotope = list[supplementingIsotopeIdx]
        var row = (idx < columnsCount) ? 0 : 1

        el.addEventListener('mouseenter', onMouseEnter, false)

        unsubscribers.push(function() {
          el.removeEventListener('mouseenter', onMouseEnter, false)
        })

        function onMouseEnter(evt) {
          el.style.height = maxHeight + 'px'
          el.style.top = (row * ISOTOPE_OVERLAP) + 'px'
          el.style.zIndex = 10
          supplementingIsotope.style.height = ISOTOPE_OVERLAP + 'px'
          supplementingIsotope.style.top = supplementingIsotopeRow * maxHeight + 'px'
          el.addEventListener('mouseleave', onMouseLeave, false)
        }

        function onMouseLeave(evt) {
          el.style.zIndex = 1
          el.style.top = (row * halfHeight) + 'px'
          el.style.height = halfHeight + 'px'
          supplementingIsotope.style.height = halfHeight + 'px'
          supplementingIsotope.style.top = supplementingIsotopeRow * (halfHeight) + 'px'
          el.removeEventListener('mouseleave', onMouseLeave)
        }
      })
    }

    function resetStyles() {
      container.style.height = ''
      container.style.position = 'relative'
      isotopesSizes.forEach(function(a, idx) {
        var el = isotopes[idx]
        el.style.transition = 'none'
        el.style.position = ''
        el.style.width = ''
        el.style.height = ''
        el.style.left = ''
        el.style.top = ''
      })
    }

    console.log('isotopes', isotopes, maxHeight);
  }

  function getColumnsCount(elems) {
    return 3
  }

  function getMaxHeight(elems) {
    return Array.prototype.reduce.call(elems, function(currentMax, el) {
      return Math.max(currentMax, el.offsetHeight);
    }, 0)
  }

}(window, document, window.LC))
