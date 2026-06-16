({
    afterScriptsLoaded : function(component, event, helper) {
        const upsellScore = component.find('upsellScore').getElement();
        const ccExpasionScore = component.find('ccExpasionScore').getElement();
        const freeScore = component.find('freeScore').getElement();
        const dlExpasionScore = component.find('dlExpasionScore').getElement();
        const rCMeetingsScore = component.find('rCMeetingsScore').getElement();
        const maxRating = 5;
        const fieldsValues = component.get('v.numberFields').split(';');
        const upsellScoreValue = fieldsValues[0];
        const ccExpasionScoreValue = fieldsValues[1];
        const freeScoreValue = fieldsValues[2];
        const dlExpasionScoreValue = fieldsValues[3];
        const rCMeetingsScoreValue = fieldsValues[4];

        component.upsellScore = helper.rating(upsellScore,upsellScoreValue,maxRating);
        component.ccExpasionScore = helper.rating(ccExpasionScore,ccExpasionScoreValue,maxRating);
        component.freeScore = helper.rating(freeScore,freeScoreValue,maxRating);
        component.dlExpasionScore = helper.rating(dlExpasionScore,dlExpasionScoreValue,maxRating);
        component.rCMeetingsScore = helper.rating(rCMeetingsScore,rCMeetingsScoreValue,maxRating);
    }
})