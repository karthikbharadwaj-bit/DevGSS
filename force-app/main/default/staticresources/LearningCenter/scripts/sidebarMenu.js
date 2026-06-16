(function(win, doc, LC){
  var elem = LC.elem
  var appendTo = LC.appendTo
  var toggleClass = LC.toggleClass
  var assign = LC.assign
  var FRIENDLY_PAGE_ID = getCurrentPageFriendlyId()
  var CURRENT_PAGE = getCurrentPageId()
  var forEach = Array.prototype.forEach

  LC.generateSidebar = generateSidebar

  return

  ///////////////////////

  function onFolderClick(e) {
    var folder = e.currentTarget
    var parent = folder.parentNode
    toggleClass(parent, 'sidebar-nav__item--is-open')
  }


  function generateSidebar() {
    try {
      var CURRENT_PAGE = getCurrentPageFriendlyId() || getCurrentPageId()
      var menuJSON = JSON.parse(window.siteMapStr)
      var menuData = transformMenuJSON(CURRENT_PAGE, menuJSON)
      var menuTree = generateMenuTree(menuData.sections)
      var menuEl = doc.querySelector('.menu')
      var hasWebForm = doc.querySelector('.contentblockwebform')
      appendTo(menuEl, menuTree)



      var nextPrevLinks = doc.querySelector('.nextPrevLinks')
      if (!nextPrevLinks) {
        console.log('No element: .nextPrevLinks');
      } else {
        // if (menuData.prevPage) {
        //   nextPrevLinks.appendChild(elem('a', {
        //     className: 'btn btn--gray btn--rounded btn--larr prevLink',
        //     href: menuData.prevPage.pageURL,
        //     style: { marginRight: 'auto' }
        //   }, 'Previous Topic: ' + menuData.prevPage.name))
        // }

        if (!hasWebForm && menuData.nextPage) {
          nextPrevLinks.appendChild(elem('a', {
            className: 'btn btn--orange btn--rounded btn--rarr nextLink',
            href: menuData.nextPage.pageURL,
            style: { marginLeft: 'auto' }
          }, 'Next Topic: ' + menuData.nextPage.name))
        }
      }

      var folders = document.querySelectorAll('.sidebar-nav__link--folder')
      forEach.call(folders, function(folder) {
        folder.addEventListener('click', onFolderClick, false)
      })

    } catch(e) {
      console.log('sidebarMenu:error', e)
    }
  }


  function generateLink(page) {
    if (page.pageURL) {
      return elem('a', {
        className: 'sidebar-nav__link',
        href: page.pageURL,
      }, page.name)
    } else {
      return elem('div', {
        className: 'sidebar-nav__link sidebar-nav__link--folder'
      }, page.name)
    }
  }

  function generatePage(page) {
    var className = 'sidebar-nav__item'
    var hasChildren = page.pages && page.pages.length > 0
    if (hasChildren) {
      className += ' sidebar-nav__item--has-children'
    }
    if (page.isActive) {
      className += ' sidebar-nav__item--is-active'
    }
    return elem('li', { className: className }, [
      generateLink(page),
      (hasChildren
        ? elem('nav', {className: 'sidebar-nav__subnav'}, [
          elem(
            'ul',
            {className: 'sidebar-nav sidebar-nav--blue-links'},
            page.pages.map(generatePage)
          )
        ])
        : null
      ),
    ])
  }

  function generateSection(section) {
    return elem('section', { className: 'sidebar-widget' }, [
      elem('div', { className: 'sidebar-widget__header' }, section.name),
      elem('div', { className: 'sidebar-widget__content' }, [
        elem(
          'ul',
          { className: 'sidebar-nav sidebar-nav--delimited-links' },
          [
            section.folders.map(generatePage),
            section.pages.map(generatePage),
          ]
        )
      ])
    ])
  }


  function generateMenuTree (json) {
    return json.map(generateSection)
  }

  function getCurrentPageId() {
    var matches = window.location.search.match(/pageid=(\w+)\b/)
    return matches && matches[1] || ''
  }

  function getCurrentPageFriendlyId() {
    var matches = window.location.pathname.match(/\/cms\/([\w\/]+)\b/)
    return matches && matches[1] || null
  }


  function processMenuItem(currentPage, menuItem, saveFirstPageAsNextPage) {
    var _tmpPrev = null
    var prevPage = null
    var nextPage = null
    isActive = false

    var folders = menuItem.folders.map(function(folder) {
      var newFolder = processMenuItem(currentPage, folder, (isActive || saveFirstPageAsNextPage) && !nextPage)
      isActive = isActive || newFolder.isActive
      if (newFolder.prevPage) { prevPage = newFolder.prevPage }
      if (newFolder.nextPage) { nextPage = newFolder.nextPage }
      return newFolder.data
    })

    var pages = menuItem.pages.map(function(page) {
      if ((isActive || saveFirstPageAsNextPage) && !nextPage) { nextPage = assign({}, page) }
      page.isActive = (page.friendlyURL === currentPage || page.pageId === currentPage)
      isActive = isActive || page.isActive
      if (!isActive) { prevPage = page }
      return page
    })

    menuItem.isActive = isActive
    menuItem.folders = folders
    menuItem.pages = pages

    return {
      prevPage: prevPage,
      nextPage: nextPage,
      isActive: isActive,
      data: menuItem,
    }
    return acc
  }


  function transformMenuJSON(currentPage, sections) {
    return sections.reduce(function(acc, section) {
      var sectionData = processMenuItem(currentPage, section, acc.isActive && !acc.nextPage)
      acc.isActive = acc.isActive || sectionData.isActive
      acc.prevPage = acc.prevPage || sectionData.prevPage
      acc.nextPage = acc.nextPage || sectionData.nextPage
      acc.sections.push(sectionData.data)
      return acc
    }, {
      isActive: false,
      prevPage: null,
      nextPage: null,
      sections: [],
    })
  }


})(window, document, window.LC)
