({	doInit : function(component, event, helper) {
    
},
  changeBooleanValue : function(component, event, helper) {
      
      //component.set("v.menuItem2",false);
      //var boolValue = event.getSource().get("v.value");
      component.set("v.menuItem1",true);
      
      
      var filename=component.get("v.publicURL");
      const extension = filename.split('.').pop();
      console.log('extension-->'+extension);
      if (extension === 'pdf' || extension === 'txt' || extension ==='zip'){
          component.set("v.isModalOpen", true);
          component.set("v.isPDF",true);
          //component.set("v.menuItem1",false);
      } else if(extension === 'mp4' || extension === 'mp3'){
          component.set("v.isModalOpen", true);
          component.set("v.isPDF",false);
          //alert('I am a video');
      }  else if(extension ==='pptx' || extension ==='ppt'){
        component.set("v.isPPT", true);
        component.set("v.isModalOpen", false);
        component.set("v.isPDF",false);
      }
      console.log('is modal open>'+component.get("v.isModalOpen"));
      console.log('is isPDF>'+component.get("v.isPDF"));
      console.log('is isPPT>'+component.get("v.isPPT"));
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