({
	init: function(component, event, helper) {
        var fieldList = component.get('v.fieldList');
        var groupList = _.filter(fieldList, function(field) {
                return field.isGroup && field.groupLabel.toLowerCase();
            })
            groupList = _.groupBy(groupList, function(field){
                if(field.groupLabel) return field.groupLabel.toLowerCase();
            });
            groupList = _.map(groupList, function(group, name){
                return helper.getGroup(group, name);
            });

        var noGroupList = _.filter(fieldList, function(field) {
                return !field.isGroup || !field.groupLabel.toLowerCase();
            });
            noGroupList = _.map(noGroupList, function(group) {
                return helper.getGroup(group);
            });

        groupList = groupList.concat(noGroupList);

        groupList.map(helper.sortByOrder.bind(helper));

        console.log('groupList ', groupList);
        component.set('v.groupList', groupList);
	}
})