/**
 * Created on 11.04.2019
 */

import { api, LightningElement, track } from "lwc";

export default class ScIframe extends LightningElement {
    @api link;
    @api params;
    @api height;
    @track h;
    @track url;
    getURLParameter(name) {
        return decodeURIComponent(
            (document.location.search.match(RegExp("[?|&]"+name+'=(.+?)(&|$)'))||[,null])[1]
        );
    }
    get locationSerach() {
        var htmlLang;
        try {
            htmlLang = document.getElementsByTagName('html')[0].getAttribute('lang').replace('-','_')
        }catch (e) {
            htmlLang = 'en_US';
        }
        if(!this.getURLParameter('language'))
            return document.location.search;
        else if(document.location.search.length < 2) {
            return '?language=' + htmlLang;
        }
        else {
            return document.location.search + '&language=' + htmlLang;
        }
    }

    fullURL() {
        if(window.top.location.pathname.indexOf('/config/commeditor.jsp') > 0) {
            this.url =  '';
        }
        else {
            this.url =  this.link + (this.params ? this.locationSerach : '');
        }
    }
    get curHeight() {
        return this.h || this.height;
    }
    resize() {
        var this_ = this;
        window.addEventListener("message", function(event) {
            if (event.origin !== document.location.origin) return;
            if (event.data.indexOf("sc_vf_resize") === 0) {
                this_.height = event.data.split('=')[1] * 1;
            }
        });
    }
    connectedCallback() {
        this.resize();
        this.fullURL()
    }
}