
RightNow.Widget.AdvancedSearchDialog=function(data,instanceID){this.data=data;this.instanceID=instanceID;YAHOO.util.Event.addListener("rn_"+this.instanceID+"_TriggerLink","click",this._openDialog,null,this);};RightNow.Widget.AdvancedSearchDialog.prototype={_openDialog:function()
{if(!this._dialog)
{var dialogDiv=document.getElementById("rn_"+this.instanceID+"_DialogContent");if(dialogDiv)
{var buttons=[{text:this.data.attrs.label_search_button,handler:{fn:this._performSearch,scope:this},isDefault:true},{text:this.data.attrs.label_cancel_button,handler:{fn:this._cancelFilters,scope:this},isDefault:false}];this._dialog=RightNow.UI.Dialog.actionDialog(this.data.attrs.label_dialog_title,dialogDiv,{"buttons":buttons});YAHOO.util.Dom.addClass(this._dialog.id,"rn_AdvancedSearchDialog");YAHOO.util.Dom.removeClass(dialogDiv,"rn_Hidden");this._dialog.hideEvent.subscribe(function(){var trigger=document.getElementById("rn_"+this.instanceID+"_TriggerLink");if(trigger&&trigger.focus)
trigger.focus();},null,this);}}
this._dialogClosed=false;this._dialog.show();this._dialog.hideEvent.subscribe(this._cancelFilters,null,this);},_performSearch:function()
{this._closeDialog();var eo=new RightNow.Event.EventObject();eo.w_id=this.instanceID;eo.filters={"report_id":this.data.attrs.report_id,"reportPage":this.data.attrs.report_page_url};RightNow.Event.fire("evt_searchRequest",eo);},_cancelFilters:function()
{if(this._dialogClosed)return;this._closeDialog();var eo=new RightNow.Event.EventObject();eo.data={"name":"all"};eo.filters={"report_id":this.data.attrs.report_id};eo.w_id=this.instanceID;RightNow.Event.fire("evt_resetFilterRequest",eo);},_closeDialog:function()
{this._dialogClosed=true;if(this._dialog)
this._dialog.hide();}};
RightNow.Widget.KeywordText2=function(data,instanceID)
{this.data=data;this.instanceID=instanceID;this._eo=new RightNow.Event.EventObject();this._textElement=document.getElementById("rn_"+this.instanceID+"_Text");if(this._textElement)
{this._searchedOn=this._textElement.value;this.data.initialValue=this._textElement.value;this._setFilter();YAHOO.util.Event.addListener(this._textElement,"change",this._onChange,null,this);RightNow.Event.subscribe("evt_keywordChangedResponse",this._onChangedResponse,this);RightNow.Event.subscribe("evt_reportResponse",this._onChangedResponse,this);RightNow.Event.subscribe("evt_getFiltersRequest",this._onGetFiltersRequest,this);RightNow.Event.subscribe("evt_resetFilterRequest",this._onResetRequest,this);if(this.data.attrs.initial_focus)
this._textElement.focus();}};RightNow.Widget.KeywordText2.prototype={_onChange:function(evt)
{this._eo.data=this._textElement.value;this._eo.filters.data=this._textElement.value;RightNow.Event.fire("evt_keywordChangedRequest",this._eo);},_onGetFiltersRequest:function(type,args)
{this._eo.filters.data=YAHOO.lang.trim(this._textElement.value);this._searchedOn=this._eo.filters.data;RightNow.Event.fire("evt_searchFiltersResponse",this._eo);},_setFilter:function()
{this._eo.w_id=this.instanceID;this._eo.filters={"searchName":this.data.js.searchName,"data":this.data.initialValue,"rnSearchType":this.data.js.rnSearchType,"report_id":this.data.attrs.report_id};},_onChangedResponse:function(type,args)
{if(RightNow.Event.isSameReportID(args,this.data.attrs.report_id))
{var data=RightNow.Event.getDataFromFiltersEventResponse(args,this.data.js.searchName,this.data.attrs.report_id),newValue=(data===null)?this.data.initialValue:data;if(this._textElement.value!==newValue)
this._textElement.value=newValue;}},_onResetRequest:function(type,args)
{if(RightNow.Event.isSameReportID(args,this.data.attrs.report_id)&&(args[0].data.name===this.data.js.searchName||args[0].data.name==="all"))
{this._textElement.value=this._searchedOn;}}};
RightNow.Widget.WebSearchSort=function(data,instanceID)
{this.data=data;this.instanceID=instanceID;this._eo=new RightNow.Event.EventObject();var optionsName="rn_"+this.instanceID+"_Options";this._searchName="webSearchSort";this._optionsSelect=document.getElementById(optionsName);RightNow.Event.subscribe("evt_sortTypeResponse",this._onChangedResponse,this);RightNow.Event.subscribe("evt_reportResponse",this._onChangedResponse,this);RightNow.Event.subscribe("evt_getFiltersRequest",this._onGetFiltersRequest,this);RightNow.Event.subscribe("evt_resetFilterRequest",this._onResetRequest,this);YAHOO.util.Event.addListener(optionsName,"change",this._onSortChange,null,this);this._setFilter();};RightNow.Widget.WebSearchSort.prototype={_setFilter:function()
{this._eo.w_id=this.instanceID;this._eo.filters.searchName=this._searchName;this._eo.filters.report_id=this.data.js.report_id;this._setDataObject();},_setDataObject:function()
{this._eo.filters.data={"col_id":(this.data.js.sortDefault!=this.data.js.configDefault)?this.data.js.sortDefault:null,"sort_direction":1,"sort_order":1};},_setSelected:function()
{if(this._optionsSelect)
{var num=this._optionsSelect.selectedIndex;num=(num<0)?0:num;if(this._optionsSelect.options[num])
{this._eo.filters.data.col_id=this._optionsSelect.options[num].value;}}},_setSelectedDropdownItem:function(valueToSelect)
{if(this._optionsSelect)
{for(var i=0;i<this._optionsSelect.length;i++)
{if(this._optionsSelect.options[i].value==valueToSelect)
{this._optionsSelect.selectedIndex=i;return true;}}}
return false;},_onSortChange:function(evt)
{this._setSelected();RightNow.Event.fire("evt_sortTypeRequest",this._eo);},_onChangedResponse:function(type,args)
{if(RightNow.Event.isSameReportID(args,this.data.attrs.report_id))
{var data=RightNow.Event.getDataFromFiltersEventResponse(args,this._searchName,this.data.attrs.report_id);var newValue=(!data||data.col_id==null)?this.data.js.sortDefault:data.col_id;if(this._eo.filters.data==null)
this._setDataObject();this._setSelectedDropdownItem(newValue);this._setSelected();}},_onResetRequest:function(type,args)
{if(RightNow.Event.isSameReportID(args,this.data.attrs.report_id)&&(args[0].data.name===this._searchName||args[0].data.name==="all"))
{this._setSelectedDropdownItem(this.data.js.sortDefault);this._setDataObject();}},_onGetFiltersRequest:function(type,args)
{RightNow.Event.fire("evt_searchFiltersResponse",this._eo);}};
RightNow.Widget.WebSearchType=function(data,instanceID)
{this.data=data;this.instanceID=instanceID;this._eo=new RightNow.Event.EventObject();var optionsName="rn_"+this.instanceID+"_Options";this._optionsSelect=document.getElementById(optionsName);this._searchName="webSearchType";RightNow.Event.subscribe("evt_searchTypeResponse",this._onChangedResponse,this);RightNow.Event.subscribe("evt_reportResponse",this._onChangedResponse,this);RightNow.Event.subscribe("evt_getFiltersRequest",this._onGetFiltersRequest,this);RightNow.Event.subscribe("evt_resetFilterRequest",this._onResetRequest,this);YAHOO.util.Event.addListener(optionsName,"change",this._onSearchChange,null,this);this._setFilter();};RightNow.Widget.WebSearchType.prototype={_setFilter:function()
{this._eo.w_id=this.instanceID;this._eo.filters={"searchName":this._searchName,"report_id":this.data.js.report_id,"data":this.data.js.searchDefault};},_setSelected:function()
{if(this._optionsSelect)
{var i=this._optionsSelect.selectedIndex;i=Math.max(0,i);if(this._optionsSelect.options[i])
{this._eo.filters.data=this._optionsSelect.options[i].value;}}},_setSelectedDropdownItem:function(valueToSelect)
{if(this._optionsSelect)
{for(var i=0;i<this._optionsSelect.length;i++)
{if(this._optionsSelect.options[i].value==valueToSelect)
{this._optionsSelect.selectedIndex=i;return true;}}}
return false;},_onSearchChange:function(evt)
{this._setSelected();RightNow.Event.fire("evt_searchTypeRequest",this._eo);},_onChangedResponse:function(type,args)
{if(RightNow.Event.isSameReportID(args,this.data.attrs.report_id))
{var data=RightNow.Event.getDataFromFiltersEventResponse(args,this._searchName,this.data.attrs.report_id);var newValue=(!data)?this.data.js.searchDefault:data;this._setSelectedDropdownItem(newValue);this._setSelected();}},_onResetRequest:function(type,args)
{if(RightNow.Event.isSameReportID(args,this.data.attrs.report_id)&&(args[0].data.name===this._searchName||args[0].data.name==="all"))
{this._setSelectedDropdownItem(this.data.js.searchDefault);this._setFilter();}},_onGetFiltersRequest:function(type,args)
{RightNow.Event.fire("evt_searchFiltersResponse",this._eo);}};
RightNow.Widget.ProductCategorySearchFilter=function(data,instanceID)
{this.data=data,this.instanceID=instanceID;this._eo=new RightNow.Event.EventObject();this._currentIndex=0;this._noValueNodeIndex=0;this._displayField=document.getElementById("rn_"+this.instanceID+"_"+this.data.attrs.filter_type+"_Button");this._displayFieldVisibleText=document.getElementById("rn_"+this.instanceID+"_ButtonVisibleText");this._accessibleView=document.getElementById("rn_"+this.instanceID+"_Links");if(!this._displayField)return;RightNow.Event.subscribe("evt_getFiltersRequest",this._getFiltersRequest,this);RightNow.Event.subscribe("evt_menuFilterGetResponse",this._getSubLevelResponse,this);RightNow.Event.subscribe("evt_accessibleTreeViewGetResponse",this._getAccessibleTreeViewResponse,this);RightNow.Event.subscribe("evt_reportResponse",this._onReportResponse,this);RightNow.Event.subscribe("evt_resetFilterRequest",this._onResetRequest,this);YAHOO.util.Event.addListener(this._displayField,"click",this._toggleProductCategoryPicker,null,this);YAHOO.util.Event.addListener("rn_"+this.instanceID+"_LinksTrigger","click",this._toggleAccessibleView,null,this);this._initializeFilter();this._panel=new YAHOO.widget.Panel("rn_"+this.instanceID+"_Tree",{close:false,width:"300px",visible:false,constraintoviewport:true});this._panel.setHeader("");this._panel.render();YAHOO.util.Dom.setStyle(this._panel.innerElement,"overflow-y","auto");if(this.data.js.defaultData)
this._buildTree();};RightNow.Widget.ProductCategorySearchFilter.prototype={_buildTree:function()
{this._initializeKeyBindings();this._tree=new YAHOO.widget.TreeView("rn_"+this.instanceID+"_Tree");if(this._tree)
{this._tree.setDynamicLoad(RightNow.Event.createDelegate(this,this._getSubLevelRequest));var root=this._tree.getRoot(),defaultValues=false;for(var i=0,node,length=this.data.js.hierData.length;i<length;i++)
{for(var j=0,nodeData;j<this.data.js.hierData[i].length;j++)
{nodeData=this.data.js.hierData[i][j];if(i!==0&&nodeData.parentID)
root=this._tree.getNodeByProperty("hierValue",nodeData.parentID);node=new YAHOO.widget.MenuNode(nodeData.label,root);node.hierValue=nodeData.value;node.href='javascript:void(0);';if(nodeData.selected)
{defaultValues=true;this._currentIndex=node.index;}
if(!nodeData.hasChildren)
{node.dynamicLoadComplete=true;node.iconMode=1;}}
root.loadComplete();}
var noValueNode=this._tree.getRoot().children[0];noValueNode.isLeaf=true;this._noValueNodeIndex=noValueNode.index;this._tree.subscribe("enterKeyPressed",this._enterPressed,null,this);this._tree.subscribe('clickEvent',this._selectNode,null,this);this._tree.subscribe('expandComplete',function(node){this._panel.innerElement.scrollTop=node.getEl().offsetTop-20;},null,this);this._tree.render();this._tree.collapseAll();YAHOO.util.Dom.setStyle("rn_"+this.instanceID+"_Tree","display","block");if(defaultValues)
this._displaySelectedNodesAndClose(false);}},_displayAccessibleDialog:function()
{if(!this._tree)
this._buildTree();if(!(this._dialog))
{var handleDismiss=function()
{this.hide();};this._buttons=[{text:RightNow.Interface.getMessage("CANCEL_CMD"),handler:handleDismiss,isDefault:false}];YAHOO.util.Dom.removeClass(this._accessibleView,"rn_Hidden")
this._dialog=RightNow.UI.Dialog.actionDialog(this.data.attrs.label_nothing_selected,this._accessibleView,{"buttons":this._buttons,"width":"400px"});}
else
{var currentlySelectedSpan=document.getElementById("rn_"+this.instanceID+"_IntroCurrentSelection");var introLink=document.getElementById("rn_"+this.instanceID+"_Intro");if(currentlySelectedSpan&&introLink)
{var currentNode=this._tree.getNodeByIndex(this._currentIndex);if(!currentNode)
{currentNode={};currentNode.hierValue=0;}
var localInstanceID=this.instanceID;introLink.onclick=function(){document.getElementById("rn_"+localInstanceID+"_AccessibleLink_"+currentNode.hierValue).focus();};var selectedNodes=this._getSelectedNodesMessage();currentlySelectedSpan.innerHTML=RightNow.Text.sprintf(RightNow.Interface.getMessage("SELECTION_PCT_S_ACTIVATE_LINK_JUMP_MSG"),selectedNodes);}}
YAHOO.lang.later(1000,this._dialog,'show');return false;},_toggleAccessibleView:function(e)
{if(this._dataType==="categories"&&this.data.js.linkingOn)
this._eo.data.linkingProduct=RightNow.UI.Form.currentProduct;if(this._flatTreeViewData)
this._displayAccessibleDialog();else
RightNow.Event.fire("evt_accessibleTreeViewRequest",this._eo);},_getAccessibleTreeViewResponse:function(e,args)
{if(args[0].data.hm_type!=this._eo.data.hm_type)
return;var evtObj=args[0];if(evtObj.data.data_type==this._dataType)
{this._flatTreeViewData=evtObj.data.accessibleLinks;var noValue={0:RightNow.Interface.getMessage("NO_VAL_LBL"),1:0,hier_list:0,level:0};if(!YAHOO.lang.isArray(this._flatTreeViewData))
{var tempArray=[];for(var i in this._flatTreeViewData)
if(!isNaN(parseInt(i)))
tempArray[i]=this._flatTreeViewData[i];this._flatTreeViewData=tempArray;}
this._flatTreeViewData.unshift(noValue);var htmlList="<p><a href='javascript:void(0)' id='rn_"+this.instanceID+"_Intro'"+"onclick='document.getElementById(\"rn_"+this.instanceID+"_AccessibleLink_"+noValue[1]+"\").focus();'>"+RightNow.Text.sprintf(RightNow.Interface.getMessage("PCT_S_LINKS_DEPTH_ANNOUNCED_MSG"),this.data.attrs.label_input)+" <span id='rn_"+this.instanceID+"_IntroCurrentSelection'>"+RightNow.Text.sprintf(RightNow.Interface.getMessage("SELECTION_PCT_S_ACTIVATE_LINK_JUMP_MSG"),noValue[0])+"</span></a></p>";var previousLevel=-1;for(var i in this._flatTreeViewData)
{if(this._flatTreeViewData.hasOwnProperty(i))
{var item=this._flatTreeViewData[i];if(item.level>previousLevel)
htmlList+="<ol>";while(item.level<previousLevel)
{htmlList+="</li></ol>";previousLevel--;}
if(item.level===previousLevel)
htmlList+="</li>";htmlList+="<li>"+'<a href="javascript:void(0)" id="rn_'+this.instanceID+'_AccessibleLink_'+item[1]+'" class="rn_AccessibleHierLink" hierList="'+item['hier_list']+'">'+item[0]+'</a>';previousLevel=item.level;}}
for(var i=previousLevel;i>=0;--i)
htmlList+="</li></ol>";htmlList+="<div id='rn_"+this.instanceID+"_AccessibleErrorLocation'></div>";this._accessibleView.innerHTML=htmlList;var allNodes=YAHOO.util.Dom.getElementsByClassName("rn_AccessibleHierLink","a",this._accessibleView);YAHOO.util.Event.addListener(allNodes,"click",this._accessibleLinkClick,null,this);this._displayAccessibleDialog();}},_accessibleLinkClick:function(e)
{var element=YAHOO.util.Event.getTarget(e);var hierArray=element.getAttribute("hierList").split(",");this._expandAndCreateNodes(hierArray);return false;},_toggleProductCategoryPicker:function(event)
{if(!this._tree)
this._buildTree();if(this._panel.cfg.getProperty("visible")===false)
{if(!this._toggleProductCategoryPicker._buttonPos||this._toggleProductCategoryPicker._buttonPos!==this._panel.cfg.getProperty("x"))
{this._toggleProductCategoryPicker._buttonPos=YAHOO.util.Dom.getX(this._displayField);this._panel.cfg.setProperty("x",this._toggleProductCategoryPicker._buttonPos);}
this._panel.syncPosition();this._panel.show();var currentNode=this._tree.getNodeByIndex(this._currentIndex);if(currentNode&&currentNode.focus)
{currentNode.focus();}
else if(this._tree.getRoot().children[0]&&this._tree.getRoot().children[0].focus)
{this._tree.getRoot().children[0].focus();}
this._toggleProductCategoryPicker._closeListener=this._toggleProductCategoryPicker._closeListener||function(event)
{if(this._panel.cfg.getProperty("visible"))
{var coordinates=YAHOO.util.Event.getXY(event);if((event.type==="click"&&YAHOO.util.Event.getTarget(event).id===this._displayField.id)||coordinates[0]===0&&coordinates[1]===0)
return;coordinates=new YAHOO.util.Point(coordinates[0],coordinates[1]);var panelRegion=YAHOO.util.Dom.getRegion("rn_"+this.instanceID+"_Tree"),buttonRegion=YAHOO.util.Dom.getRegion(this._displayField);if(panelRegion&&buttonRegion&&(!panelRegion.contains(coordinates)&&!buttonRegion.contains(coordinates)))
{this._displaySelectedNodesAndClose();YAHOO.util.Event.removeListener(document,this._toggleProductCategoryPicker._closeListener);}}};YAHOO.util.Event.addListener(document,"click",this._toggleProductCategoryPicker._closeListener,null,this);}
else
{this._displaySelectedNodesAndClose();YAHOO.util.Event.removeListener(document,this._toggleProductCategoryPicker._closeListener);}},_getSelectedNodesMessage:function()
{this._currentIndex=this._currentIndex||1;var hierValues=[],currentNode=this._tree.getNodeByIndex(this._currentIndex);while(currentNode&&!currentNode.isRoot())
{hierValues.push(currentNode.label);currentNode=currentNode.parent;}
return hierValues.reverse();},_displaySelectedNodesAndClose:function(focus)
{RightNow.Event.fire("evt_productCategoryFilterSelected",this._eo);this._panel.hide();if(this._dialog&&this._dialog.cfg.getProperty("visible"))
this._dialog.hide();if(this._currentIndex<=this._noValueNodeIndex)
{this._displayFieldVisibleText.innerHTML=this.data.attrs.label_nothing_selected;var description=document.getElementById("rn_"+this.instanceID+"_TreeDescription");if(description)
description.innerHTML=this.data.attrs.label_nothing_selected;}
else
{var hierValues=this._getSelectedNodesMessage().join("<br/>"),field=this._displayFieldVisibleText;if(YAHOO.env.ua.webkit){setTimeout(function(){field.innerHTML=hierValues;},1);}
else{field.innerHTML=hierValues;}
var description=document.getElementById("rn_"+this.instanceID+"_TreeDescription");if(description)
description.innerHTML=this.data.attrs.label_screen_reader_selected+hierValues;}
if(focus&&!this._dialog)
try{this._displayField.focus();}catch(e){}},_enterPressed:function(keyEvent)
{this._selectNode({node:keyEvent});},_selectNode:function(clickEvent)
{this._currentIndex=clickEvent.node.index;this._selected=true;this._selectNode._selectedWidget=this.data.info.w_id;if(clickEvent.node.expanded||this._noValueNodeIndex===clickEvent.node.index)
{this._eo.data.level=clickEvent.node.depth+1;if(this._eo.data.level!==this._eo.filters.data[0].length)
{this._eo.filters.data[0]=[];var currentNode=clickEvent.node;while(currentNode&&!currentNode.isRoot())
{this._eo.filters.data[0][currentNode.depth]=currentNode.hierValue;currentNode=currentNode.parent;}}
else
{this._eo.filters.data[0][this._eo.data.level-1]=this._eo.data.value;for(var i=this._eo.data.level;i<this._eo.filters.data[0].length;i++)
delete this._eo.filters.data[0][i];}}
else
{this._getSubLevelRequest(clickEvent.node);this._tree.collapseAll();}
this._displaySelectedNodesAndClose(true);if(clickEvent.event)
YAHOO.util.Event.preventDefault(clickEvent.event);return false;},_getSubLevelRequest:function(expandingNode)
{if(this._nodeBeingExpanded||expandingNode.expanded)return;this._nodeBeingExpanded=true;this._eo.data.level=expandingNode.depth+1;this._eo.data.label=expandingNode.label;this._currentIndex=expandingNode.index;this._eo.data.value=expandingNode.hierValue;this._getSubLevelRequest._origRequest=this._getSubLevelRequest._origRequest||[];this._getSubLevelRequest._origRequest[this._dataType]=expandingNode.hierValue;if(this._dataType==="products")
{RightNow.UI.Form.currentProduct=this._eo.data.value;}
if(this._eo.data.value<1&&this._eo.data.linking_on)
{this._eo.data.reset=true;if(this._eo.data.value===0&&this._dataType==="products")
{this._eo.data.reset=false;var eo=new RightNow.Event.EventObject();eo.data={"name":"c","reset":true};eo.filters.report_id=this.data.attrs.report_id;RightNow.Event.fire("evt_resetFilterRequest",eo);this._nodeBeingExpanded=false;return;}
else
{this._eo.data.value=0;}}
else
{this._eo.data.reset=false;}
if(this.data.js.link_map)
{this._eo.data.link_map=this.data.js.link_map;this.data.js.link_map=null;}
if(this._eo.data.level!==this._eo.filters.data[0].length)
{this._eo.filters.data[0]=[];var currentNode=expandingNode;while(currentNode&&!currentNode.isRoot())
{this._eo.filters.data[0][currentNode.depth]=currentNode.hierValue;currentNode=currentNode.parent;}}
else
{this._eo.filters.data[0][this._eo.data.level-1]=this._eo.data.value;for(var i=this._eo.data.level;i<this._eo.filters.data[0].length;i++)
delete this._eo.filters.data[0][i];}
RightNow.Event.fire("evt_menuFilterRequest",this._eo);this._nodeBeingExpanded=false;},_onReportResponse:function(type,args)
{if(RightNow.Event.isSameReportID(args,this.data.attrs.report_id)){var data=RightNow.Event.getDataFromFiltersEventResponse(args,this.data.js.searchName,this.data.attrs.report_id);if(data[0]&&data[0].length){if(!this._tree)
this._buildTree();if(typeof data[0]==="string")
data[0]=data[0].split(",");var finalData=RightNow.Lang.arrayFilter(data[0]);this._expandAndCreateNodes(finalData);this._eo.filters.data[0]=finalData;this._lastSearchValue=finalData.slice(0);if(this._eo.filters.data.reconstructData){this._eo.filters.data.level=this._eo.filters.data.reconstructData.level;this._eo.filters.data.label=this._eo.filters.data.reconstructData.label;}}
else if(this._tree){this._eo.filters.data[0]=[];this._currentIndex=this._noValueNodeIndex;this._displaySelectedNodesAndClose();}}},_expandAndCreateNodes:function(hierArray)
{var i=hierArray.length-1,currentNode=null;while(!currentNode&&i>=0){currentNode=this._tree.getNodeByProperty("hierValue",parseInt(hierArray[i]));i--;}
if(this._currentIndex===currentNode.index)
{if(this._dialog&&this._dialog.cfg.getProperty("visible"))
this._dialog.hide();return;}
i++;if(this._noValueNodeIndex===currentNode.index||currentNode.hierValue==hierArray[hierArray.length-1]){this._selectNode({node:currentNode});}
else{var onExpandComplete=function(expandingNode){if(expandingNode.nextToExpand){var nextNode=this._tree.getNodeByProperty("hierValue",parseInt(expandingNode.nextToExpand));if(nextNode){nextNode.nextToExpand=hierArray[++i];nextNode.expand();}}
else if(i===hierArray.length){this._tree.unsubscribe("expandComplete",onExpandComplete,null);expandingNode.expanded=false;this._selectNode({node:expandingNode});}
return true;};this._tree.subscribe("expandComplete",onExpandComplete,null,this);currentNode.nextToExpand=hierArray[++i];currentNode.expand();}},_getSubLevelResponse:function(type,args)
{var evtObj=args[0];if((evtObj.data.data_type!==this._dataType)||(evtObj.filters.report_id!==this.data.attrs.report_id))
return;var hierLevel=evtObj.data.level,hierData=evtObj.data.hier_data,redisplaySelectedNode=false,currentRoot=null;if(!this._tree)
this._buildTree();if(!evtObj.data.reset_linked_category&&this._getSubLevelRequest._origRequest&&this._getSubLevelRequest._origRequest[this._dataType])
{currentRoot=this._tree.getNodeByProperty("hierValue",this._getSubLevelRequest._origRequest[this._dataType]);if(currentRoot.index!==this._currentIndex)
{this._currentIndex=currentRoot.index;redisplaySelectedNode=true;}}
else if(evtObj.data.reset_linked_category)
{currentRoot=this._tree.getRoot();currentRoot.dynamicLoadComplete=false;this._tree.removeChildren(currentRoot);this._flatTreeViewData=null;var tempNode=new YAHOO.widget.MenuNode(RightNow.Interface.getMessage("NO_VAL_LBL"),currentRoot,false);tempNode.hierValue=0;tempNode.href='wsdindex.htmljavascript:void(0);';tempNode.isLeaf=true;this._noValueNodeIndex=this._currentIndex=tempNode.index;this._displayFieldVisibleText.innerHTML=this.data.attrs.label_nothing_selected;var description=document.getElementById("rn_"+this.instanceID+"_TreeDescription");if(description)
description.innerHTML=this.data.attrs.label_nothing_selected;}
if(hierLevel<7&&!currentRoot.dynamicLoadComplete)
{for(var i=0,tempNode,hasChildrenIndex;i<hierData.length;i++)
{hasChildrenIndex=hierData[i].length-1;tempNode=new YAHOO.widget.MenuNode(hierData[i][1],currentRoot,false);tempNode.hierValue=hierData[i][0];tempNode.href='wsdindex.htmljavascript:void(0);';if(!hierData[i][hasChildrenIndex]||hierLevel===6)
{tempNode.dynamicLoadComplete=true;tempNode.iconMode=1;}}
currentRoot.loadComplete();}
if(hierData.length===0&&!this._selected)
{this._displaySelectedNodesAndClose();}
else if(this._selected)
{this._selected=false;}
else if(redisplaySelectedNode&&this._selectNode._selectedWidget)
{this._selectNode._selectedWidget=null;this._displaySelectedNodesAndClose();}},_getFiltersRequest:function(type,args)
{if(this._tree)
{this._eo.filters.data.reconstructData=[];if(this._currentIndex!==this._noValueNodeIndex)
{var currentNode=this._tree.getNodeByIndex(this._currentIndex||this._noValueNodeIndex),hierValues,level;this._eo.data.level=currentNode.depth+1;this._eo.data.label=currentNode.label;this._eo.data.value=currentNode.hierValue;while(currentNode&&!currentNode.isRoot())
{level=currentNode.depth+1;hierValues=this._eo.filters.data[0].slice(0,level).join(",");this._eo.filters.data.reconstructData.push({"level":level,"label":currentNode.label,"hierList":hierValues});currentNode=currentNode.parent;}
this._eo.filters.data.reconstructData.reverse();}
else
{this._eo.filters.data[0]=[];this._eo.data.value=0;}}
this._lastSearchValue=this._eo.filters.data[0].slice(0);RightNow.Event.fire("evt_searchFiltersResponse",this._eo);},_onResetRequest:function(type,args)
{if(this._tree&&RightNow.Event.isSameReportID(args,this.data.attrs.report_id)&&(args[0].data.name===this.data.js.searchName||args[0].data.name==="all"))
{if(args[0].data.name==="all"&&this._lastSearchValue)
{this._eo.filters.data[0]=this._lastSearchValue;this._currentIndex=this._tree.getNodeByProperty("hierValue",this._lastSearchValue[this._lastSearchValue.length-1]).index;}
else
{if(args[0].data.reset&&this.data.js.linkingOn&&this._dataType==="categories")
{this._buildTree();}
this._eo.filters.data[0]=[];this._currentIndex=this._noValueNodeIndex;}
this._displaySelectedNodesAndClose();}},_initializeFilter:function()
{this._eo.w_id=this.instanceID;this._eo.data.data_type=this._dataType=this.data.attrs.filter_type;this._eo.data.linking_on=this.data.js.linkingOn;this._eo.data.cache=[];this._eo.data.hm_type=this.data.js.hm_type;this._eo.data.linkingProduct=0;this._eo.filters={"rnSearchType":"menufilter","searchName":this.data.js.searchName,"report_id":this.data.attrs.report_id,"fltr_id":this.data.js.fltr_id,"oper_id":this.data.js.oper_id,"data":[]};this._eo.filters.data[0]=(this.data.js.initial)?this.data.js.initial:[];this._lastSearchValue=this._eo.filters.data[0].slice(0);if(this._dataType==="products")
{RightNow.UI.currentProduct=this._eo.filters.data[0][this._eo.filters.data[0].length-1];RightNow.UI.linkingOn=this.data.js.linkingOn;RightNow.UI.linkingFilter=this.data.attrs.filter_name;}},_initializeKeyBindings:function()
{if(!this._initializeKeyBindings._initialized){this._initializeKeyBindings._initialized=true;YAHOO.widget.TreeView.prototype._onKeyDownEvent=function(ev){var target=YAHOO.util.Event.getTarget(ev),node=this.getNodeByElement(target),newNode=node,KEY=YAHOO.util.KeyListener.KEY;switch(ev.keyCode){case KEY.UP:do{if(newNode.previousSibling){var currentNode=newNode.previousSibling;while(currentNode&&currentNode.expanded&&currentNode.children.length){currentNode=currentNode.children[currentNode.children.length-1];}
newNode=currentNode;}
else{newNode=newNode.parent;}}
while(newNode&&!newNode._canHaveFocus());if(newNode)
newNode.focus();YAHOO.util.Event.preventDefault(ev);break;case KEY.DOWN:do{if(newNode.children.length&&newNode.expanded){newNode=newNode.children[0];}
else if(newNode.nextSibling){newNode=newNode.nextSibling;}
else{var currentNode=newNode.parent;while(currentNode){if(currentNode.nextSibling){newNode=currentNode.nextSibling;break;}
else{currentNode=currentNode.parent;}}}}
while(newNode&&!newNode._canHaveFocus);if(newNode)
newNode.focus();YAHOO.util.Event.preventDefault(ev);break;case KEY.LEFT:node.collapse();YAHOO.util.Event.preventDefault(ev);break;case KEY.RIGHT:node.expand();YAHOO.util.Event.preventDefault(ev);break;case KEY.ENTER:case KEY.TAB:if(node.href){if(node.target){window.open(node.href,node.target);}
else{window.location(node.href);}}
else{node.toggle();}
this.fireEvent('enterKeyPressed',node);YAHOO.util.Event.preventDefault(ev);break;case KEY.HOME:newNode=this.getRoot();if(newNode.children.length)
newNode=newNode.children[0];if(newNode._canHaveFocus())
newNode.focus();YAHOO.util.Event.preventDefault(ev);break;case KEY.END:newNode=newNode.parent.children;newNode=newNode[newNode.length-1];if(newNode._canHaveFocus())
newNode.focus();YAHOO.util.Event.preventDefault(ev);break;case 107:if(ev.shiftKey){node.parent.expandAll();}
else{node.expand();}
break;case 109:if(ev.shiftKey){node.parent.collapseAll();}
else{node.collapse();}
break;default:break;}};}}};
RightNow.Widget.SortList2=function(data,instanceID)
{this.data=data;this.instanceID=instanceID;this._eo=new RightNow.Event.EventObject();var headingsName="rn_"+this.instanceID+"_Headings";var directionName="rn_"+this.instanceID+"_Direction";this._headingsSelect=document.getElementById(headingsName);this._directionSelect=document.getElementById(directionName);RightNow.Event.subscribe("evt_sortTypeResponse",this._onChangedResponse,this);RightNow.Event.subscribe("evt_reportResponse",this._onChangedResponse,this);RightNow.Event.subscribe("evt_getFiltersRequest",this._onGetFiltersRequest,this);RightNow.Event.subscribe("evt_resetFilterRequest",this._onResetRequest,this);YAHOO.util.Event.addListener(headingsName,"change",this._onSelectChange,null,this);YAHOO.util.Event.addListener(directionName,"change",this._onDirectionChange,null,this);this._setFilter();};RightNow.Widget.SortList2.prototype={_onSelectChange:function(evt)
{this._setSelected();RightNow.Event.fire("evt_sortTypeRequest",this._eo);if(this.data.attrs.search_on_select)
{this._eo.filters.reportPage=this.data.attrs.report_page_url;RightNow.Event.fire("evt_searchRequest",this._eo);}},_onDirectionChange:function(evt)
{this._setDirection();RightNow.Event.fire("evt_sortTypeRequest",this._eo);if(this.data.attrs.search_on_select)
{this._eo.filters.reportPage=this.data.attrs.report_page_url;RightNow.Event.fire("evt_searchRequest",this._eo);}},_setDirection:function()
{if(this._directionSelect)
{var num=this._directionSelect.selectedIndex;num=(num<0)?0:num;if(this._directionSelect.options[num])
{this._eo.filters.data.sort_direction=this._directionSelect.options[num].value;}}},_setSelected:function()
{if(this._headingsSelect)
{var num=this._headingsSelect.selectedIndex;num=(num<0)?0:num;if(this._headingsSelect.options[num])
{this._eo.filters.data.col_id=this._headingsSelect.options[num].value;}}},_setSelectedDropdownItem:function(selectBox,valueToSelect)
{if(selectBox)
{for(var i=0;i<selectBox.length;i++)
{if(selectBox.options[i].value==valueToSelect)
{selectBox.selectedIndex=i;return true;}}}
return false;},_setFilter:function()
{this._eo.w_id=this.instanceID;this._eo.filters.searchName=this.data.js.searchName;this._eo.filters.report_id=this.data.attrs.report_id;this._setDataObject();},_setDataObject:function()
{this._eo.filters.data={"col_id":this.data.js.col_id,"sort_direction":this.data.js.sort_direction};},_onChangedResponse:function(type,args)
{if(RightNow.Event.isSameReportID(args,this.data.attrs.report_id))
{var data=RightNow.Event.getDataFromFiltersEventResponse(args,this.data.js.searchName,this.data.attrs.report_id);if(this._eo.filters.data===null)
this._setDataObject();var newValue=(!data||data.col_id==null)?this.data.js.col_id:data.col_id;this._setSelectedDropdownItem(this._headingsSelect,newValue);this._setSelected();newValue=(!data||data.sort_direction==null)?this.data.js.sort_direction:data.sort_direction;this._setSelectedDropdownItem(this._directionSelect,newValue);this._setDirection();}},_onResetRequest:function(type,args)
{if(RightNow.Event.isSameReportID(args,this.data.attrs.report_id)&&(args[0].data.name===this.data.js.searchName||args[0].data.name==="all"))
{this._setSelectedDropdownItem(this._headingsSelect,this.data.js.col_id);this._setSelectedDropdownItem(this._directionSelect,this.data.js.sort_direction);this._setFilter();}},_onGetFiltersRequest:function(type,args)
{RightNow.Event.fire("evt_searchFiltersResponse",this._eo);}};
RightNow.Widget.SearchButton2=function(data,instanceID)
{this.data=data;this.instanceID=instanceID;this._requestInProgress=false;this._searchButton=document.getElementById("rn_"+this.instanceID+"_SubmitButton");this._enableClickListener();RightNow.Event.subscribe("evt_reportResponse",this._onSearchResponse,this);};RightNow.Widget.SearchButton2.prototype={_startSearch:function(evt)
{if(this._requestInProgress)return false;if(!this.data.attrs.popup_window)
this._disableClickListener();if(YAHOO.env.ua.ie!==0)
{if(!this._parentForm)
this._parentForm=YAHOO.util.Dom.getAncestorByTagName("rn_"+this.instanceID,"FORM");if(this._parentForm&&window.external&&"AutoCompleteSaveForm"in window.external)
{window.external.AutoCompleteSaveForm(this._parentForm);}}
var eo=new RightNow.Event.EventObject();eo.w_id=this.instanceID;eo.filters={report_id:this.data.attrs.report_id,reportPage:this.data.attrs.report_page_url,target:this.data.attrs.target};RightNow.Event.fire("evt_searchRequest",eo);},_onSearchResponse:function(type,args)
{if(args[0].filters.report_id==this.data.attrs.report_id)
this._enableClickListener();},_enableClickListener:function()
{this._searchButton.disabled=this._requestInProgress=false;YAHOO.util.Event.addListener(this._searchButton,"click",this._startSearch,null,this);},_disableClickListener:function()
{this._searchButton.disabled=this._requestInProgress=true;YAHOO.util.Event.removeListener(this._searchButton,"click",this._startSearch);}};
RightNow.Widget.Multiline2=function(data,instanceID){this.data=data;this.instanceID=instanceID;this._eo=new RightNow.Event.EventObject();this._contentName="rn_"+this.instanceID+"_Content";this._loadingName="rn_"+this.instanceID+"_Loading"
if(RightNow.Event.isHistoryManagerFragment())
this._setLoading(true);RightNow.Event.subscribe("evt_reportResponse",this._onReportChanged,this);RightNow.Event.subscribe("evt_searchInProgressRequest",this._searchInProgress,this);this._setFilter();RightNow.Event.fire("evt_setInitialFiltersRequest",this._eo);};RightNow.Widget.Multiline2.prototype={_setFilter:function()
{this._eo.w_id=this.instanceID;this._eo.filters={"report_id":this.data.attrs.report_id,"token":this.data.js.r_tok,"allFilters":this.data.js.filters,"format":this.data.js.format};this._eo.filters.format.parmList=this.data.attrs.add_params_to_url;},_searchInProgress:function(type,args)
{if(args[0].filters.report_id==this.data.attrs.report_id)
{this._setLoading(true);}},_setLoading:function(loading)
{if(loading)
{var element=document.getElementById(this._contentName);if(element)
{YAHOO.util.Dom.setStyle(element,"height",element.offsetHeight+"px");if(YAHOO.env.ua.ie)
YAHOO.util.Dom.addClass(element,"rn_Hidden");else
(new YAHOO.util.Anim(element,{opacity:{to:0}},0.4,YAHOO.util.Easing.easeIn)).animate();YAHOO.util.Dom.addClass(this._loadingName,"rn_Loading");}}
else
{YAHOO.util.Dom.removeClass(this._loadingName,"rn_Loading");if(YAHOO.env.ua.ie)
YAHOO.util.Dom.removeClass(this._contentName,"rn_Hidden");else
(new YAHOO.util.Anim(this._contentName,{opacity:{to:1}},0.4,YAHOO.util.Easing.easeIn)).animate();}},_onReportChanged:function(type,args)
{var newdata=args[0].data;this._setLoading(false);if(newdata.report_id==this.data.attrs.report_id)
{var currentPageSize=newdata.per_page;var cols=newdata.headers.length;var str="";var report=document.getElementById(this._contentName);if(!report)
return;if(newdata.total_num>0)
{if(newdata.row_num)
str+='<ol start="'+newdata.start_num+'">';else
str+='<ul>';for(var i=0;i<currentPageSize;i++)
{str+='<li>';str+='<span class="rn_Element1">'+newdata.data[i][0]+'&nbsp;</span>';str+=(newdata.data[i][1])?'<span class="rn_Element2">'+newdata.data[i][1]+'</span>':'';str+='<br/>';str+=(newdata.data[i][2])?'<span class="rn_Element3">'+newdata.data[i][2]+'</span><br/>':'';for(var j=3;j<cols;j++)
{str+='<span class="rn_ElementsHeader">'+newdata.headers[j]['heading'];if(newdata.headers[j]['heading']!="")
str+=':&nbsp;';str+='</span>';str+='<span class="rn_ElementsData">'+newdata.data[i][j]+'</span><br/>';}
str+='</li>';}
if(newdata.row_num)
str+='</ol>';else
str+='<ul>';report.innerHTML=str;}
else
{report.innerHTML="";}
YAHOO.util.Dom.setStyle(report,"height","auto");RightNow.Url.transformLinks(report);var anchors=report.getElementsByTagName('a');if(anchors&&anchors[0])
anchors[0].focus();}}};