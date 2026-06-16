/* 0.082463979721069 */function UI_Select_Options(hash) {
	this.__construct(hash || {});
}

UI_Select_Options.prototype = {

	_getElementsByClassName : getElementsByClassName,
	_addEvent : addEvent,
	_setCssClassName : setCssClassName,
	_getCssClassNameValue : getCssClassNameValue,

	__construct: function(hash){
		this._selectAreaClass = hash.selectAreaClass || 'selectarea';
		this._selectInputClass = hash.selectInputClass || 'select-top';
		this._selectItemClass = hash.selectItemClass || 'select-item';
		this._toogleClass = hash.toogleClass || 'selectoptions';
		this._toogleHideValue = hash.toogleHideValue || 'hide';
		this._toogleDisplayValue = hash.toogleDisplayValue || 'display';
		this._selectedItemClass = hash.selectedItemClass || 'item';
		this.value='';
		this._init();
	},

	_init: function() {
		this._select = this._getElementsByClassName(this._selectAreaClass, document, 'div')[0];
		this._selectInput = this._getElementsByClassName(this._selectInputClass, this._select, 'div')[0];
		this._selectInputField = this._selectInput.getElementsByTagName('p')[0];

		this._addEvent(document, 'onclick', this.closeSelect.rcBindAsIs(this));
		this._addEvent(this._selectInput, 'onclick', function(e) {
			if(e) {
				e.cancelBubble = true;
				if (typeof e.stopPropagation == 'function') {
					e.stopPropagation();
				}
			}
			this.onSelectClick();
		}.rcBindAsIs(this));
		this._initItems();
	},

	_initItems: function() {
		this._items = this._getElementsByClassName(this._selectItemClass, this._select, 'div');
		for(var i in this._items) {
			var node = this._items[i];
			var index = +i + 1;
			var innerField = node.getElementsByTagName('p')[0];
			this._addEvent(node, 'onclick', this.onAfterClickItem.rcBindAsIs(this, {value: innerField.innerHTML, selectedIndex: index}));
		}
	},

	closeSelect: function() {
		if (typeof this._select != 'undefined') {
			this._setCssClassName(this._select, this._toogleClass, this._toogleHideValue);
		}
	},

	openSelect: function() {
		if (typeof this._select != 'undefined') {
			this._setCssClassName(this._select, this._toogleClass, this._toogleDisplayValue);
		}
	},

	onSelectClick: function() {
		var currentSate = this._getCssClassNameValue(this._select, this._toogleClass);
		if (currentSate == this._toogleDisplayValue) {
			this.closeSelect();
		} else {
			this.openSelect();
		}
	},

	onAfterClickItem: function(hash){
		this.closeSelect();
		this.onSelectedItemChanged(hash);
	},

	onSelectedItemChanged: function(hash){
		this._selectInputField.innerHTML = hash.value || '';
		this._selectInputField.className='';
		this.value=hash.value;
		this._setCssClassName(this._select, this._selectedItemClass, hash.selectedIndex);
	}
};
function RequestQuote() {
	this.__construct();
}

RequestQuote.prototype ={
	__construct : function(){
	  this.params=[];
  	    this.count = new UI_Select_Options({selectAreaClass: 'select1'});
		this._parent =getElementsByClassName('MarkerTabState', document.body, 'div')[0];
	},

	setDefault : function(inputs){
		each(inputs, function(node, i){
			node.className='default';
			node.value=node.getAttribute('def');
			node.onfocus=function(){
				if(this.value==this.getAttribute('def')){
					this.value='';
				}
				this.className='';
			}
			node.onblur=function(){
				if(this.value==''){
					this.className='default';
					this.value=this.getAttribute('def');
				}else{
					this.className='';
				}
			}
		})
	},
	NextStep : function(){
	  if(this.count.value == ''){
			alert('Please selected.');return;
		}
	},
	SendRequest : function(){
	  if(this.term.value == ''){
			alert('Please selected.');return;
		}
	  }
}
addEvent(window, 'ondomready',
    function(){
        RequestObj = new RequestQuote();
    }
)
