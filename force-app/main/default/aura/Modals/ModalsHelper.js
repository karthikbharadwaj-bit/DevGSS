({
    getClasses: function(){

        function Modals(){
            this.modals = [];

            this.get = function( guid ){
                return this.modals.filter(function( modal ){
                    return modal.guid === guid;
                })[0];
            };

            this.add = function( config ){
                this.modals.push( new RC.modalHelper.Modal( config ) );
            };
        }

        return {
            Modals: Modals
        }
    }
});