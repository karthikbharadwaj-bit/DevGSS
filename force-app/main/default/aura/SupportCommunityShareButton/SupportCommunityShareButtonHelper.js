/**
 * Created on 05.02.2019
 */
({
    supplant: function (s,o) {
        return s.replace(/{([^{}]*)}/g,
            function (a, b) {
                var r = o[b];
                return typeof r === 'string' || typeof r === 'number' ? r : a;
            }
        );
    },
    networks: function() {
        return {
            email:{link: ' mailto:?subject={title}&body={url}'},
            bookmark:{},
            facebook: { width : 600, height : 300, link: 'https://www.facebook.com/sharer/sharer.php?u={url}&t={title}'},
            googleplus: { width : 515, height : 490, link: 'https://plus.google.com/share?url={url}', icon: 'Google' },
            linkedin: { width : 600, height : 473, link: 'https://www.linkedin.com/shareArticle?mini=true&url={url}&title={title}' },
            print: {},
            pinterest: {width : 777, height : 347, link: 'http://pinterest.com/pin/create/button/?url={url}&description={title}'},
            reddit: {width : 600, height : 453, link: 'https://www.reddit.com/submit?url={url}'},
            tumblr: {width : 720, height : 488, link: 'http://www.tumblr.com/share?v=3&u={url}&t={title}&s='},
            twitter: { width : 600, height : 254, link: 'https://twitter.com/share?url={url}&text={title}' }
        }
    },
    init: function(cmp) {
      var buttons = [];
      for(var i=1; i<=10; i++) {
          var type =  cmp.get('v.share_'+i);
          if(type !== '- none -' && type !== '') {
              var button = {};
              button.title = type;
              button.icon = this.networks()[type.toLowerCase()].icon || type;
              button.link = this.supplant(this.networks()[type.toLowerCase()].link || '',
                  {
                      url: encodeURIComponent(document.location.href),
                      title: encodeURIComponent(document.title)
                     }
              );
              buttons.push(button);
          }
      }
        cmp.set('v.buttons',buttons);
    },
    popup: function(href, network) {
        var options = 'menubar=no,toolbar=no,resizable=yes,scrollbars=yes,';
        window.open(href, '', options+'height='+network.height+',width='+network.width);
    },
    openShare: function(target, url) {

        this.popup(url, this.networks()[target]);
    },
    print: function() {
        window.print();
    },
    bookmarkMe: function() {
        if (window.sidebar && window.sidebar.addPanel) {
            // Mozilla Firefox Bookmark
            window.sidebar.addPanel(document.title, window.location.href, "");
        } else if (window.external && "AddFavorite" in window.external) {
            // IE Favorite
            window.external.AddFavorite(location.href, document.title);
        } else if (window.opera && window.print) {
            // Opera Hotlist
            this.title = document.title;
            return true;
        } else {
            // webkit - safari/chrome
            alert(
                "Press " +
                    (navigator.userAgent.toLowerCase().indexOf("mac") != -1 ? "Command/Cmd" : "CTRL") +
                    " + D to bookmark this page."
            );
        }
    },
});