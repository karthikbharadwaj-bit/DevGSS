/* 0.43222594261169 */
function $_(id){return document.getElementById(id);}
(function(){function getCookie(name){re=RegExp(name+"=(.*?)(;|$)","i")
if(res=re.exec(document.cookie))
return res[1];return null;}
if(getCookie("debug_is")){if(!$_('showControl')){document.write('<span id="showControl" ondblclick ="this.innerHTML = \'\'" style="background-color:white;position:absolute;left:0px;top:0px;z-Index:10000"></span>')}
if(!/msie 6/i.test(navigator.userAgent)&&!$_('showStopper')){document.write('<iframe id="showStopper" style="display: none"></iframe>');}}})();function showStopper(time)
{var param=time?'param[sleep]='+time:'';if($_('showStopper'))
{$_('showStopper').src='/api/index.php?cmd=showStopper&api=collector&'+param;}}
function hash_to_string(hash)
{arr=[];for(key in hash){try{arr.push(key+':'+hash[key]);}catch(e){}}
return arr.join(',');}
function show(obj,cmd){str='';for(key in obj){try{str+='&nbsp;&nbsp;&nbsp;&nbsp;<b>'+key+'</b>='+(obj[key]&&obj[key][cmd]?obj[key][cmd]:obj[key])+'<br>';}catch(e){}}
switch(cmd){case'inTail':$_('showControl').innerHTML+=str!=''?str:'<b>EMPTY</b>';break;default:$_('showControl').innerHTML=str!=''?str:'<b>EMPTY</b>';break;}}
function printArray(arr){$_('showControl').innerHTML='<pre>'+print_r(arr,true);}
function print_r(array,return_val){var output="",pad_char=" ",pad_val=4;var formatArray=function(obj,cur_depth,pad_val,pad_char){if(cur_depth>0){cur_depth++;}
var base_pad=repeat_char(pad_val*cur_depth,pad_char);var thick_pad=repeat_char(pad_val*(cur_depth+1),pad_char);var str="";if(obj instanceof Array||obj instanceof Object){str+="Array\n"+base_pad+"(\n";for(var key in obj){str+=thick_pad+"["+key+"] => "+formatArray(obj[key],cur_depth+1,pad_val,pad_char)+'<br>';}
str+=base_pad+")\n";}else{if(obj&&obj.toString){str=obj.toString();}}
return str;};var repeat_char=function(len,pad_char){var str="";for(var i=0;i<len;i++){str+=pad_char;};return str;};output=formatArray(array,0,pad_val,pad_char);if(return_val!==true){document.write("<pre>"+output+"</pre>");return true;}else{return output;}}
Function.prototype.bind=function(obj){var method=this;var arg=Array();for(var i=0;i<arguments.length;i++){if(i){arg.push(arguments[i])}}
return function(E){var arg_=Array();for(var i=0;i<arguments.length;i++){if(arguments[i]instanceof Array||arguments[i]instanceof Object){arg_.push(arguments[i]);}}
if(arg_.length){arg=arg_.concat(arg);}
returnVal=method.apply(obj,arg);window.addEvent(window,'onunload',function(){method=null;arg=null;obj=null;})
return returnVal;}}
Function.prototype.rcBind=function(obj)
{var m=this;var a=arguments.length>1?arguments[1]:{};return function(e)
{if(arguments.length)
{if(arguments[0].srcElement||arguments[0].target)
{a['oEvent']=arguments[0];}
else
{for(var key in arguments[0])
{a[key]=arguments[0][key];}}}
return m.call(obj,a);}}
Function.prototype.rcBindAsIs=function(obj)
{var method=this;var arg=[];for(var i=1;i<arguments.length;i++)
{arg.push(arguments[i]);}
return function()
{if(arguments.length)
{for(var i=0;i<arguments.length;i++)
{arg.push(arguments[i]);}}
var res=null;res=method.apply(obj,arg);if(arguments.length)
{for(var i=0;i<arguments.length;i++)
{arg.pop();}}
return res;}}
function addEvent(obj,ev,func,useCapture)
{useCapture=!useCapture?false:true;if(ev=='ondomready')
{onDomReady(func);return;}
if(ev!='onunload'){window.addEvent(window,'onunload',function(){window.removeEvent(obj,ev,func);func=null;})}
if(window.addEventListener)
{obj.addEventListener(ev.replace(/^on/i,''),func,useCapture);}
if(window.attachEvent){obj.attachEvent(ev,func);}}
function onDomReady(callback)
{var _timer;var onDomReadyCallBack=function()
{if(arguments.callee.done)return;arguments.callee.done=true;if(_timer)
{clearInterval(_timer);_timer=null;}
callback();};if(document.addEventListener)
{document.addEventListener("DOMContentLoaded",onDomReadyCallBack,false);}
if(document.attachEvent&&!$_('__ie_onload'))
{}
if(document.attachEvent&&document.documentElement.doScroll&&window==window.top)
{(function()
{try
{document.documentElement.doScroll("left");}
catch(error)
{setTimeout(arguments.callee,0);return;}
onDomReadyCallBack();})();}
if(document.attachEvent)
{}
if(/WebKit/i.test(navigator.userAgent))
{_timer=setInterval(function()
{if(/loaded|complete/.test(document.readyState))
{onDomReadyCallBack();}},10);}
addEvent(window,'onload',onDomReadyCallBack);}
function removeEvent(obj,ev,func){if(window.addEventListener){obj.removeEventListener(ev.replace(/^on/i,''),func,false);}
if(window.detachEvent){obj.detachEvent(ev,func);}}
function in_array(needle,haystack,strict){var found=false,key,strict=!!strict;for(key in haystack){if((strict&&haystack[key]===needle)||(!strict&&haystack[key]==needle)){found=true;break;}}
return found;}
function count(mixed_var,mode){var key,cnt=0;if(mode=='COUNT_RECURSIVE')mode=1;if(mode!=1)mode=0;for(key in mixed_var){cnt++;if(mode==1&&mixed_var[key]&&(mixed_var[key].constructor===Array||mixed_var[key].constructor===Object)){cnt+=count(mixed_var[key],1);}}
return cnt;}
function is_string(mixed_var){return(typeof(mixed_var)=='string');}
function is_numeric(mixed_var){return!isNaN(mixed_var);}
function is_dom(obj){return obj&&obj.style;}
function is_oObj(obj){return obj&&obj.getView&&obj.getView();}
is_vObj=is_oObj;function is_array(mixed_var){return(mixed_var instanceof Array);}
function is_object(mixed_var){if(mixed_var instanceof Array){return false;}else{return(mixed_var!==null)&&(typeof(mixed_var)=='object');}}
function is_numeric(mixed_var){return!isNaN(mixed_var);}
function empty(mixed_var){var is_object_empty=false;if(is_object(mixed_var)){for(key in mixed_var){return is_object_empty;}
is_object_empty=true;}
return(mixed_var===""||mixed_var===0||mixed_var==="0"||mixed_var===null||mixed_var===false||(is_array(mixed_var)&&mixed_var.length===0)||is_object_empty);}
function is_obj(obj){return obj&&typeof(obj);}
function strToJson(str)
{if(typeof str!='string')
{str='';}
var res={};try
{res=(new Function('return '+str.replace(/^[^{]*|[^}]$/,'')))();}
catch(e){};return res;}
function getChilds(obj,nodeName,attr,style,arr){if(!arr){arr=Array();}
if(obj.hasChildNodes()){for(var i=0;i<obj.childNodes.length;i++){if(obj.childNodes[i].nodeName=='#text'){continue;}
if(!nodeName||obj.childNodes[i].nodeName==nodeName){if(!attr){if(!style){arr.push(obj.childNodes[i]);}else{if(obj.childNodes[i].style){var flg=false;for(key in style){var re=new RegExp(style[key])
if(obj.childNodes[i].style[key].match(re)){flg=true;}else{flg=false;break;}}
if(flg){arr.push(obj.childNodes[i]);}}}}else{var flg=false;for(key in attr){if(obj.childNodes[i].getAttribute(key)==attr[key]){flg=true;}else{flg=false;break;}}
if(flg){if(!style){arr.push(obj.childNodes[i]);}else{if(obj.childNodes[i].style){var flg=false;for(key in style){if(obj.childNodes[i].style[key]==style[key]){flg=true;}else{flg=false;break;}}
if(flg){arr.push(obj.childNodes[i]);}}}}}}
getChilds(obj.childNodes[i],nodeName,attr,style,arr);}}
return arr;}
function errorMsg(method,msg){alert("Error:\r\r\n\n    "+method+"                        \r\n    "+msg);}
function noticeMsg(method,msg){alert('Notice!!!:\r\r    '+method+'                        \r    '+msg+'!');}
function returnFalse(event){event.cancelBubble=true;return false;}
function getNextBrother(obj){if(!is_dom(obj)){errorMsg('tools.js -> Window :: getNextBrother','Object in not DOM element');return;}}
function parseXML(xml){var arr=Array();if(!xml||!xml.firstChild){return'';}
var root=xml.nodeName=='#document'?xml.firstChild:xml;if(root.nodeName=='#text'){root=root.nextSibling;}
if(root.nodeName=='xml'){root=root.nextSibling;}
if(root){for(var i=0;i<root.childNodes.length;i++){var item=root.childNodes[i];var nodeName=item.nodeName;var attributes=getAttributes(item);if(nodeName!='#text'){if(nodeName!="#comment"){switch(nodeName){case'length':case'push':nodeName='_'+nodeName;break;}
var val=parseXML(item);if(!arr[nodeName]){if(attributes){var temp=Array();temp['attrs']=attributes;temp['textContent']=val;arr[nodeName]=temp;}else{arr[nodeName]=val;}}else{if(!is_array(arr[nodeName])){var temp=arr[nodeName];arr[nodeName]=Array(temp);}
if(arr[nodeName].length==0){var temp=arr[nodeName];arr[nodeName]=Array(temp);}
if(attributes){var temp=Array();temp['attrs']=attributes;temp['textContent']=val;arr[nodeName].push(temp);}else{arr[nodeName].push(val);}}}}}
var flg=false;for(key in arr){flg=true;break;}
return flg?arr:(root.text||root.textContent);}
return null;}
function getAttributes(node){var arr=Array();if(node&&node.attributes&&node.attributes.length>0){for(var i=0;i<node.attributes.length;i++){var attr=node.attributes[i];arr[attr.name]=attr.value;}
return arr;}
return null;}
function formatPhoneNumber(number){return number.substring(0,1)+' ('+number.substring(1,4)+') '+number.substring(4,7)+'-'+number.substring(7,11);}
function templater(str,hash)
{var leftQ='<%';var rightQ='%>';var re1=new RegExp("((^|"+rightQ+")[^\t]*)'",'g');var re2=new RegExp("\t=(.*?)\\"+rightQ,'g');var my_str="var a=[];with(hash){a.push('"+str.replace(/[\t\r\n]/g," ").split(leftQ).join("\t").replace(re1,"$1\r").replace(re2,"',$1,'").split("\t").join("');").split(rightQ).join("a.push('").split("\r").join("\\'")+"');} return a.join('');";my_str='try{'+my_str+'}catch(e){throw e;}';return new Function("hash",my_str)(hash);}
function getCssClassNamevalue(o,className)
{var sClasses=o.className.replace(/\n|\r|\t/g,' ');var aClasses=sClasses.split(' ');var re=new RegExp('^'+className+'(\-|)([^\-]+|)','');for(var i=0;i<aClasses.length;i++)
{var class_=aClasses[i];if(res=class_.match(re))
{return res[2];}}
return null;}
getCssClassNameValue=getCssClassNamevalue
function setCssClassName(o,className,value)
{if(getCssClassNameValue(o,className)==value)
{return;}
if(typeof value=='undefined')
{o.className=className;}
else
{var sClasses=o.className.replace(/\n|\r|\t/g,' ');var aClasses=sClasses.split(' ');var re=new RegExp('^'+className+'\-.+','');for(var i=0;i<aClasses.length;i++)
{var class_=aClasses[i];if(class_.match(re))
{aClasses.splice(i,1);}}
if(value==''&&value!=0)
{aClasses.push(className);}
else
{aClasses.push(className+'-'+value);}
o.className=aClasses.join(' ');if(o.firstChild&&o.firstChild.tagName=='B')
{o.firstChild.innerHTML=o.className;}}}
function addClassName(o,className)
{var aClasses=o.className.replace(/\n|\r|\t/g,' ').split(' ');for(var i=0;i<aClasses.length;i++)
{if(aClasses[i]==className)
{return;}}
o.className+=' '+className;}
function initCss(rules)
{if(!rules||typeof rules!='string')
{return false;}
try
{var oStyle=document.createElement('DIV');oStyle.innerHTML='*<style>'+rules+'</style>*';document.getElementsByTagName('HEAD')[0].appendChild(oStyle);}
catch(e)
{var oStyle=document.createElement('STYLE');oStyle.innerHTML=rules;document.body.appendChild(oStyle);}
return true;}
function getElementsByClassName(classNameVal,parent,tag)
{var res=[];parent=parent||document;var nodes=parent.getElementsByTagName(tag||'*');var l=nodes.length;if(l)
{var re=new RegExp("(^|\\s)"+classNameVal+"(\\s|$)");for(var i=0;i<l;i++)
if(re.test(nodes[i].className))res.push(nodes[i]);}
return res;}
function each(obj,callBack,space)
{if(!obj)
{throw new Error('Each\nObject is undefined');}
if(typeof callBack!='function')
{throw new Error('Each\nCallBack undefined or not a function');}
space=space||obj;if(obj.length)
{for(var i=0,l=obj.length;i<l;i++){if(callBack.call(space,obj[i],parseInt(i),obj)===false)
return false;}}
else
{for(var key in obj){if(obj.hasOwnProperty&&obj.hasOwnProperty(key)){if(callBack.call(space,obj[key],key,obj)===false)
return false;}}}
return true;}
function getCurrentStyle(o,name)
{if(window.getComputedStyle)
{return window.getComputedStyle(o,null)[name];}else if(o.currentStyle)
{return o.currentStyle[name];}
return null;}
function each_r(obj,callBack,space)
{if(!obj)
{throw new Error('Each\nObject is undefined');}
if(typeof callBack!='function')
{throw new Error('Each\nCallBack undefined or not a function');}
space=space||obj;var res=[];if(obj.length)
{for(var i=0,l=obj.length;i<l;i++){var ret_val=callBack.call(space,obj[i],i,obj);if(ret_val)
{res.push(ret_val);}}}
else
{for(var key in obj){if(obj.hasOwnProperty(key)){var ret_val=callBack.call(space,obj[key],key,obj);if(ret_val)
{res.push(ret_val);}}}}
return res.length?res:null;}
function getCssPropValueBySelectorAndProp(selector,prop)
{var css=window.document.styleSheets;if(css.length)
{var res=each_r(css,(function(selector,prop,cssGroup)
{try
{var fullRules=cssGroup.cssRules||cssGroup.rules
if(fullRules)
{var res=each_r(fullRules,(function(selector,prop,rule)
{if(rule.selectorText==selector)
{return rule.style[prop];}
return null;}).rcBindAsIs(this,selector,prop));return res?res:null;}}catch(e){}}).rcBindAsIs(this,selector,prop));return res?res[0]:null;}}
function inArray(arr,val)
{if(arr)
{for(var i=0,l=arr.length;i<l;i++)
{if(arr[i]==val)
{return i;}}}
return-1;}
function opacity(id,opacStart,opacEnd,millisec){var speed=Math.round(millisec/100);var timer=0;if(opacStart>opacEnd){for(i=opacStart;i>=opacEnd;i--){setTimeout("changeOpac("+i+",'"+id+"')",(timer*speed));timer++;}}else if(opacStart<opacEnd){for(i=opacStart;i<=opacEnd;i++)
{setTimeout("changeOpac("+i+",'"+id+"')",(timer*speed));timer++;}}}
function changeOpac(opacity,id){var object=document.getElementById(id).style;object.opacity=(opacity/100);object.MozOpacity=(opacity/100);object.KhtmlOpacity=(opacity/100);object.filter="alpha(opacity="+opacity+")";}
function getParentByTagsName(arr,node)
{while(inArray(arr,node.nodeName)==-1)
{if(node.nodeName=='BODY')
{return null;}
node=node.parentNode;}
return node;}
function fireEvent(el,ev)
{if(document.createEventObject)
{var E=document.createEventObject();el.fireEvent(ev,E);return true;}
else if(document.createEvent)
{var E=document.createEvent("MouseEvents");E.initEvent(ev.replace(/^on/,''),true,false);el.dispatchEvent(E);var E=document.createEvent("HTMLEvents");E.initEvent(ev.replace(/^on/,''),true,false);el.dispatchEvent(E);return true;}
else
{return false;}}
function rand(min,max){var argc=arguments.length;if(argc==0){min=0;max=2147483647;}else if(argc==1){throw new Error('Warning: rand() expects exactly 2 parameters, 1 given');}
return Math.floor(Math.random()*(max-min+1))+min;}
function concatHash()
{var r={};for(var i=0;i<arguments.length;i++)
{var parent=arguments[i];for(var key in parent)
{r[key]=parent[key];}}
return r;}