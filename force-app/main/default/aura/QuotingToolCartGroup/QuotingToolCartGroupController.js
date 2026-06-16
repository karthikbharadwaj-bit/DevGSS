({
	showList: function(component, event, helper) {
	  var isShowList = component.get('v.isShowList');
	  isShowList = !isShowList;
	  component.set('v.isShowList', isShowList);
	  }
})