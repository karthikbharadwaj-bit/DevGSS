({	doInit : function(component, event, helper) {
    
},
  changeBooleanValue : function(component, event, helper) {
      
      //component.set("v.menuItem2",false);
      //var boolValue = event.getSource().get("v.value");
      component.set("v.menuItem1",true);
      
      
      var filename=component.get("v.publicURL");
      const extension = filename.split('.').pop();
      
      if (extension === 'pdf' || extension === 'txt' || extension ==='zip'){
          component.set("v.isModalOpen", true);
          component.set("v.isPDF",true);
          //component.set("v.menuItem1",false);
      } else if(extension === 'mp4' || extension === 'mp3'){
          component.set("v.isModalOpen", true);
          component.set("v.isPDF",false);
          //alert('I am a video');
      }  
  },
  openModel: function(component, event, helper) {
      // Set isModalOpen attribute to true
      component.set("v.isModalOpen", true);
  },
  
  closeModel: function(component, event, helper) {
      // Set isModalOpen attribute to false  
      component.set("v.isModalOpen", false);
  },
 })