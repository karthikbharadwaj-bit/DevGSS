import { LightningElement, api, track } from "lwc";
import SVG_URL from '@salesforce/resourceUrl/sc_icons';

export default class SCShareButton extends LightningElement {
    @api label;
    @api share_1 = "Facebook";
    @api share_2 = "Twitter";
    @api share_3 = "LinkedIn";
    @api share_4 = "Email";
    @api share_5 = "Bookmark";
    @api share_6 = "Print";
    @api share_7;
    @api share_8;
    @api share_9;
    @api share_10;
    @track buttons = [];
    get svgURL() {
        return SVG_URL;
    }
    get networks() {
        return {
            email: {
                link: "mailto:?subject={title}&body={url}"
            },
            bookmark: {},
            facebook: {
                width: 600,
                height: 300,
                link: "https://www.facebook.com/sharer/sharer.php?u={url}&t={title}"
            },
            googleplus: {
                width: 515,
                height: 490,
                link: "https://plus.google.com/share?url={url}",
                icon: "Google"
            },
            linkedin: {
                width: 600,
                height: 473,
                link: "https://www.linkedin.com/shareArticle?mini=true&url={url}&title={title}"
            },
            print: {},
            pinterest: {
                width: 777,
                height: 347,
                link: "http://pinterest.com/pin/create/button/?url={url}&description={title}"
            },
            reddit: {
                width: 600,
                height: 453,
                link: "https://www.reddit.com/submit?url={url}"
            },
            tumblr: {
                width: 720,
                height: 488,
                link: "http://www.tumblr.com/share?v=3&u={url}&t={title}&s="
            },
            twitter: {
                width: 600,
                height: 254,
                link: "https://twitter.com/share?url={url}&text={title}"
            }
        };
    }
    supplant(s, o) {
        return s.replace(/{([^{}]*)}/g, function(a, b) {
            var r = o[b];
            return typeof r === "string" || typeof r === "number" ? r : a;
        });
    }
    connectedCallback() {

        this.buttons = [];
        for (var i = 1; i <= 10; i++) {
            const type = this["share_" + i];
            if (type && type !== "- none -" && type !== "") {
                var button = {};
                button.Id = i;
                button.title = type;

                button.icon = '#sc-icons-' + (this.networks[type.toLowerCase()].icon || type);
                button.link = this.supplant(this.networks[type.toLowerCase()].link || "", {
                    url: encodeURIComponent(document.location.href),
                    title: encodeURIComponent(document.title)
                });
                this.buttons.push(button);
            }
        }
    }
    shareClick(event) {
        var el = event.currentTarget;
        var target = el.getAttribute("title").toLowerCase();
        var url = el.getAttribute("href");
        switch(target) {
            case 'print':
                event.preventDefault();
                this.print();
                break;
            case 'bookmark':
                event.preventDefault();
                this.bookmarkMe();
                break;
            case 'email':
                break;
            default:
                event.preventDefault();
                this.openShare(target, url);
                break;
        }
    }
    popup(href, network) {
        var options = 'menubar=no,toolbar=no,resizable=yes,scrollbars=yes,';
        window.open(href, '', options+'height='+network.height+',width='+network.width);
    }
    openShare(target, url) {
        this.popup(url, this.networks[target]);
    }
    print() {
        window.print();
    }
    bookmarkMe() {
        if (window.sidebar && window.sidebar.addPanel) { // Mozilla Firefox Bookmark
            window.sidebar.addPanel(document.title, window.location.href, '');
        } else if (window.external && window.external.AddFavorite) { // IE Favorite
            window.external.AddFavorite(location.href, document.title);
        } else if (window.opera && window.print) { // Opera Hotlist
            this.title = document.title;
            return true;
        } else { // webkit - safari/chrome
            alert('Press ' + (navigator.userAgent.toLowerCase().indexOf('mac') != -1 ? 'Command/Cmd' : 'CTRL') + ' + D to bookmark this page.');
        }
    }
}