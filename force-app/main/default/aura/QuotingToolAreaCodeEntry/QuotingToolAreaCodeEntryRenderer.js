({
    afterRender: function (component, helper) {
        this.superAfterRender();
        helper.checkDisabling(component);
    },

    rerender : function(component, helper){
      this.superRerender();

      helper.calcColumns(component);
    }
})