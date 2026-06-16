({
  showPopover: function(target, textMsg, iconTheme, iconCollection){
    if (!textMsg) return;

    var params = {
        target: target,
        show: true,
        showIcon: true,
        iconTheme: iconTheme,
        preferredPosition: 'top',
        text: textMsg
    };

    if(iconCollection)
        params.iconCollection = iconCollection;

    $A.get("e.c:PopoverEvent").setParams(params).fire();
  }
});