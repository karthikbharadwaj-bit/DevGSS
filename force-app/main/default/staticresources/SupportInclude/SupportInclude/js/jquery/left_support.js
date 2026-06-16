var pageUrl = $(location).attr('href');
var paramPosition = pageUrl.indexOf('?');
if(paramPosition != -1) {
	pageUrl = pageUrl.substr(0, paramPosition);
}
var fileName = pageUrl.substr(pageUrl.lastIndexOf('/') + 1);
var testCharsPosition = fileName.lastIndexOf('_');
if(testCharsPosition != -1) {
	var testChars = fileName.substring(testCharsPosition + 1, fileName.lastIndexOf('.'));
	var firstTestChar = testChars.substr(0, 1);
	var regex = new RegExp(firstTestChar, 'g');
	if(testChars.replace(regex, '').length == 0) {
		pageUrl = pageUrl.replace(fileName, fileName.substr(0, testCharsPosition) + fileName.substr(fileName.lastIndexOf('.')));
	}
}

function initMenus() {
	var originalTabsPosition = $('#tp1').css('bottom');
	var linkMenuHeader;
	var linkSubMenu;
	var linkTopMenu;
	var isCurrentPageTopMenuHeader = true;
	var currentPageTopMenu;
	var activeTopMenuClass;

	$('#left-nav ul li').each(
		function() {
			if($(this).find('a:eq(0)').attr('href') != undefined && $(this).find('a:eq(0)').attr('href') != '') {
				$(this).click(
					function(e) {
						window.location = $(this).find('a:eq(0)').attr('href');
					}
				);
			}
			//console.log($(this).find('a:eq(0)').attr('href'));
		}
	);
	jQuery.expr[':'].regex = function(elem, index, match) {
		var matchParams = match[3].split(','),
		validLabels = /^(data|css):/,
		attr =
		{
			method: matchParams[0].match(validLabels) ?
			matchParams[0].split(':')[0] : 'attr',
			property: matchParams.shift().replace(validLabels,'')
		},
		regexFlags = 'ig',
		regex = new RegExp(matchParams.join('').replace(/^\s+|\s+$/g,''), regexFlags);

		return regex.test(jQuery(elem)[attr.method](attr.property));
	}

	$('#left-nav ul li a.linkTop').each(
		function() {
			if($(this).attr('href') == undefined || $(this).attr('href') == '') {
				$(this).css('cursor', 'default');
			}
		}
	);

	var subMenus = $(':regex(id,^menu)');
	$(subMenus).each(
		function() {
			$(this).hide();
			$(this).children('li:first').css('border-top', 'none');
			var linkSubMenu = $(this);
			var subMenuLink;
			$(this).children('li.noSubMenu').each(
				function() {
					subMenuLink = $(this).children('a');
					if (urlMatch($(subMenuLink).attr('href'))) {
						isCurrentPageTopMenuHeader = false;
						currentPageTopMenu = linkSubMenu;
						$(subMenuLink).addClass('active-menu-header').addClass('current-page-menu-header');
					}
				}
			);
		}
	);
	if (! isCurrentPageTopMenuHeader) {
		i = 0;
		$(':regex(class,^li-item-F)').each(
			function() {
				var liLink = $(this);
				if($(liLink).parent().find('ul:eq('+i+')').attr('id') == $(currentPageTopMenu).attr('id')) {
					$(currentPageTopMenu).show();
					linkTopMenu = $(this);
					var topMenuItemCounter = 0;
					$('#left-nav ul.level-1').children('li').each(
						function() {
							topMenuItemCounter++;
							if($(this).attr('class') == $(linkTopMenu).attr('class')) {
								activeTopMenuClass = 'active-' + topMenuItemCounter;
							}
						}
					);
				}
				i++;
			}
		);
	}
	else {
		topMenuItemCounter = 0;
		$('#left-nav ul li a.linkTop').each(
			function() {
				topMenuItemCounter++;
				if($(this).attr('href') != undefined && $(this).attr('href') != '' && urlMatch($(this).attr('href'))) {
					activeTopMenuClass = 'active-' + topMenuItemCounter;
				}
			}
		);
	}
	$('#left-nav').addClass(activeTopMenuClass);
	repositionTabs(originalTabsPosition);

    $('li.li-item-F').click(
		function(e) {
		    $('li.li-item-F2').removeClass("opened");
		    $('li.li-item-F3').removeClass("opened");
            $(this).toggleClass("opened");
        }
    );
    $('li.li-item-F2').click(
		function(e) {
		    $('li.li-item-F').removeClass("opened");
		    $('li.li-item-F3').removeClass("opened");
            $(this).toggleClass("opened");
        }
    );
    $('li.li-item-F3').click(
		function(e) {
		    $('li.li-item-F').removeClass("opened");
		    $('li.li-item-F2').removeClass("opened");
            $(this).toggleClass("opened");
        }
    );


	$('#left-nav ul li').click(
		function(e) {
			var this_link = $(this).find('a:eq(0)').attr('href');
			if(this_link == undefined || this_link == '') {
				var topLinkBackgroundImage = $(this).css('background-image');
				var linkTopMenu = $(this);
				var linkTopMenuOrdinal;
				var linkSubMenu;
				if(typeof $(linkTopMenu).next('ul').attr('id') == 'undefined')
					linkSubMenu = $(linkTopMenu).find('ul:eq(0)');
				else linkSubMenu = $(linkTopMenu).next('ul');
				var topMenuItemCounter = 0;
				if($(this).css('background-color')!='#005691' && $(this).css('background-color')!='rgb(0, 86, 145)') {
					$('#left-nav ul li a.linkTop').parents('li[class^=li-item-F]').each(function() {
						$(this).css('background-image',$(this).css('background-image').replace('blue-bottom','blue-right'));
					});
				}
				$('#left-nav ul.level-1').children('li').each(
					function() {
						topMenuItemCounter++;
						if($(this).attr('class') == $(linkTopMenu).attr('class')) {
							linkTopMenuOrdinal = topMenuItemCounter;
						}
					}
				);
				if($(linkSubMenu).is(':visible')) {
					topLinkBackgroundImage = topLinkBackgroundImage.replace('bottom', 'right');
					if(!$('#left-nav ul.level-1').parent().hasClass('active-' + linkTopMenuOrdinal)) {
						$(this).css('background-image', topLinkBackgroundImage);
						$(linkSubMenu).slideUp('normal');
					}
				}
				else {
					topLinkBackgroundImage = topLinkBackgroundImage.replace('right', 'bottom');
					$(this).css('background-image', topLinkBackgroundImage);
					$(subMenus).each(
						function() {
							var isCurrentPageInSubMenu = false;
							$(this).children('li.noSubMenu').each(
								function() {
									if(urlMatch($(this).children('a').attr('href'))) {
										isCurrentPageInSubMenu = true;
									}
								}
							);
							if(!isCurrentPageInSubMenu) {
								$(this).slideUp('normal');
							}
						}
					);
					$(linkSubMenu).slideDown('normal');

				}
				repositionTabs(originalTabsPosition);
				e.preventDefault();
			}
		}
	);
}

function repositionTabs(originalTabsPosition) {
	if($.browser.msie) {
		if($('#tp1').css('position') == 'absolute') {
			window.setTimeout(
				function() {
					$('#tp1').hide().css('bottom', '0px').css('bottom', originalTabsPosition).show();
				}, 500
			);
		}
	}
}

function urlMatch(linkUrl) {
	var isMatch;
	if(linkUrl == undefined || linkUrl == '') {
		isMatch = false;
	}
	else if(/\/whyringcentral\/company\/pressreleases\/(.)?/.test(pageUrl) && linkUrl == '/whyringcentral/company/pressreleases.html') {
		isMatch = true;
	}
	else if(/\/whyringcentral\/inthenews\/(.)?/.test(pageUrl) && linkUrl == '/whyringcentral/inthenews.html') {
		isMatch = true;
	}
	else if(/\/whyringcentral\/awards\/(.)?/.test(pageUrl) && linkUrl == '/whyringcentral/awards.html') {
		isMatch = true;
	}
	else if(/\/whyringcentral\/casestudies\/(.)?|\/whyringcentral\/casestudies_mobile\.html|\/whyringcentral\/casestudies_fax\.html/.test(pageUrl) && linkUrl == '/whyringcentral/casestudies.html') {
		isMatch = true;
	}
	else if(/\/whyringcentral\/testimonials\/(.)?/.test(pageUrl) && linkUrl == '/whyringcentral/testimonials.html') {
		isMatch = true;
	}
	else if(/\/smb\/successstories\/(.)?/.test(pageUrl) && linkUrl == '/smb/successstories/index.html') {
		isMatch = true;
	}
	else if(/\/whyringcentral\/jobs\/(.)?/.test(pageUrl) && linkUrl == '/whyringcentral/jobs.html') {
		isMatch = true;
	}
	else if(/\/whyringcentral\/$/.test(pageUrl) && linkUrl == '/whyringcentral.html') {
		isMatch = true;
	}
	else {
		if(linkUrl == pageUrl || linkUrl == pageUrl.substr(pageUrl.length - linkUrl.length)) {
			isMatch = true;
		}
		else {
			isMatch = false;
		}
	}
	return isMatch;
}

$(document).ready(function() {initMenus();});