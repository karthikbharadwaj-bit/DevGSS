import { LightningElement, api, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getAccountHierarchyData from '@salesforce/apex/AccountStructure.findHierarchyData';
// import { updateRecord } from 'lightning/uiRecordApi';

// importing Static Resources
import tableJS                  from '@salesforce/resourceUrl/RCTABLEJS';
import tableCSS                 from '@salesforce/resourceUrl/RCTABLECSS';

// importing resource loader
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';


export default class AccountHierarchy extends LightningElement {

    // Make a Component Aware of Its Record Context
    // https://developer.salesforce.com/docs/component-library/documentation/lwc/lwc.use_object_context
    @api recordId;


    //accountHierarchyData; // Holding variable used in refreshApex for Fast Track Requests (hold data and error)
    @track accountHierarchy;
		@track accountHierarchy2;
		@track accountHierarchy3;
		@track accountHierarchy4;
		@track accountHierarchy5;
		@track accountHierarchy6;
		@track accountHierarchy7;
		@track accountHierarchy8;
    @track numberOfAccounts;

    @track isRenderedCallBackInitialized = false;
    @track filterData ='NotCanceled';
		@track filterData2 ='NotFree';
		@track filterData3 ='NotNullAcc';

    @track baseURL;


    // Get the Hierarchy Data related to the Account
    @wire(getAccountHierarchyData, { recId : '$recordId',oldfilter : 'Canceled'})
    getAccountHierarchyData(result)
    {
        console.log('In Wired Data');
        const { data, error } = result;
				console.log ('Result : ' + result);
				console.log ('Error : ' + JSON.stringify(result));

        if(data)
        {
            //this.accountHierarchyData = data;
            this.accountHierarchy = data;//Entire data
            //this.numberOfAccounts = this.accountHierarchyData.length;
						var obj = JSON.parse(JSON.stringify(result));
            var res = [];
						var res2 = [];
						var res3 = [];
						var res4 = [];
						var res5 = [];
						var res6 = [];
						var res7 = [];
						console.log ('Data Length : ' + data.length);
						for(var i=0; i<data.length; i++)
								{
										if(data[i].RC_Account_Status__c!='Canceled' && data[i].RC_Account_Status__c!='Free' && (data[i].RC_Account_Status__c!='' || data[i].RecordTypeId=='0122H000000URz8QAG'))//Loading page without Canceled,Free and null
												{
														res.push(data[i]);
												}
								}
						for(var i=0; i<data.length; i++)
								{
										if(data[i].RC_Account_Status__c!='Free' && (data[i].RC_Account_Status__c!='' || data[i].RecordTypeId=='0122H000000URz8QAG'))//Data showing with canceled
												{
														res2.push(data[i]);
												}
								}						
						for(var i=0; i<data.length; i++)
								{
										if(data[i].RC_Account_Status__c!='Canceled' && (data[i].RC_Account_Status__c!='' || data[i].RecordTypeId=='0122H000000URz8QAG'))//Data showing with Free
												{
														res3.push(data[i]);
												}
								}						
						for(var i=0; i<data.length; i++)
								{
										if(data[i].RC_Account_Status__c!='Free' && data[i].RC_Account_Status__c!='Canceled')//Data showing with null
												{
														res4.push(data[i]);
												}
								}					
						for(var i=0; i<data.length; i++)
								{
										if(data[i].RC_Account_Status__c!='' || data[i].RecordTypeId=='0122H000000URz8QAG')//Data showing with Canceled and Free
												{
														res5.push(data[i]);
												}
								}											
						for(var i=0; i<data.length; i++)
								{
										if(data[i].RC_Account_Status__c!='Free')//Data showing with Canceled and null
												{
														res6.push(data[i]);
												}
								}											
						for(var i=0; i<data.length; i++)
								{
										if(data[i].RC_Account_Status__c!='Canceled')//Data showing with Free and null
												{
														res7.push(data[i]);
												}
								}
						console.log(`Account Hierarchy Array: `+res);
            this.accountHierarchy2 = res;//Loading page without Canceled,Free and null
						this.accountHierarchy3 = res2;
						this.accountHierarchy4 = res3;
						this.accountHierarchy5 = res4;
						this.accountHierarchy6 = res5;
						this.accountHierarchy7 = res6;
						this.accountHierarchy8 = res7;
            this.initializeAccountHierarchy();
        }
    }

    renderedCallback() {

        console.log ('In Method Rendered Call Back');
        this.baseURL = window.location.origin;
        if (this.isRenderedCallBackInitialized) {
            return;
        }

        loadScript(this, tableJS).then(() => {
            loadStyle(this, tableCSS).then(() => {
                console.log('Scripts Loaded Successfully');
                // this.initializeAccountHierarchy();
                this.isRenderedCallBackInitialized = true;
                // });
            });
        });

    }

    convertToStructuredJSON(data)  {
        // Keep a fast lookup dictionary
        var accountData = {};
        accountData = JSON.parse(JSON.stringify(data));
				//console.log ('accountData : ' + accountData.RC_Account_Status__c);
        var dictionary = {};
        for (var i = 0; i < accountData.length; i++) {
            dictionary[accountData[i].Id] = accountData[i];
        }
				console.log ('dictionary : ' + dictionary);
        console.log ('Here');
        for (var i = 0; i < accountData.length; i++) {
            if (accountData[i].ParentId) {
                var parent = dictionary[accountData[i].ParentId];
                if (parent) {
                    if (!parent._children) {
                        parent._children = [];
                    }
                    parent._children.push(accountData[i]);
                }
            }
        }
				console.log ('accountData end : ' + accountData);
        return accountData;
    }

    handleFilterDataChange (event) {
				console.log('Filter Data : ' + event + 'as'+event.target.name);
				if(event.target.checked==false)
        this.filterData = 'Canceled';
				else
				this.filterData = '';		
				console.log('filter datas 1 :'+this.filterData+'2:'+this.filterData2+'3:'+this.filterData3);
        this.initializeAccountHierarchy();

    }
		
		handleFilterDataChange2 (event) {
				console.log('Filter Data : ' + event + 'as'+event.target.name);
				if(event.target.checked==false)
        this.filterData2 = 'Free';
				else
				this.filterData2 = '';	
				console.log('filter datas 1 :'+this.filterData+'2:'+this.filterData2+'3:'+this.filterData3);
        this.initializeAccountHierarchy();

    }
		
		handleFilterDataChange3 (event) {
				console.log('Filter Data : ' + event + 'as'+event.target.name);
				if(event.target.checked==false)
        this.filterData3 = 'NullAcc';
				else
				this.filterData3 = '';
				console.log('filter datas 1 :'+this.filterData+'2:'+this.filterData2+'3:'+this.filterData3);
        this.initializeAccountHierarchy();

    }

    initializeAccountHierarchy() {

        this.component = this.template.querySelector('[data-id="RCTableData"]');

        console.log ('In Method : initializeAccountHierarchy');
        console.log (this.component);

                //define row context menu contents
                var rowMenu = [];
        
        //define row context menu
        var headerMenu = [];

        var hideIcon = function(cell, formatterParams, onRendered){ //plain text value
            return "<i class='fa fa-eye-slash'></i>";
        };
        // console.log('Filter Data Value : ' + this.filterData);
        console.log('Data : ' + JSON.stringify(this.convertToStructuredJSON(this.accountHierarchy)));
        var sfdcURL = this.baseURL;
				console.log('URL :'+sfdcURL);
        //define table

        //create font awesome icon
        var expandEl = document.createElement("i");
				var dataMap;
				console.log('filter datas inside 1 :'+this.filterData+'2:'+this.filterData2+'3:'+this.filterData3);
				if(this.filterData!='Canceled' && this.filterData2!='Free' && this.filterData3!='NullAcc')
						dataMap= this.convertToStructuredJSON(this.accountHierarchy2);
				else if(this.filterData=='Canceled' && this.filterData2!='Free' && this.filterData3!='NullAcc')
						dataMap= this.convertToStructuredJSON(this.accountHierarchy3);
				else if(this.filterData!='Canceled' && this.filterData2=='Free' && this.filterData3!='NullAcc')
						dataMap= this.convertToStructuredJSON(this.accountHierarchy4);
				else if(this.filterData!='Canceled' && this.filterData2!='Free' && this.filterData3=='NullAcc')
						dataMap= this.convertToStructuredJSON(this.accountHierarchy5);
				else if(this.filterData=='Canceled' && this.filterData2=='Free' && this.filterData3!='NullAcc')
						dataMap= this.convertToStructuredJSON(this.accountHierarchy6);
				else if(this.filterData=='Canceled' && this.filterData2!='Free' && this.filterData3=='NullAcc')
						dataMap= this.convertToStructuredJSON(this.accountHierarchy7);
				else if(this.filterData!='Canceled' && this.filterData2=='Free' && this.filterData3=='NullAcc')
						dataMap= this.convertToStructuredJSON(this.accountHierarchy8);
				else
						dataMap= this.convertToStructuredJSON(this.accountHierarchy);
        expandEl.classList.add("fas");
        expandEl.classList.add("fa-plus-square");

        console.log ('Record ID : ' + this.recordId);

        var recordIdTemp = this.recordId;
        var table = new RCTable(this.component, {
            height:"100%",
            layout:"fitColumns",
            dataTree:true,
            //initialFilter:[
            //    {field:"RC_Account_Status__c", type:"like", value:this.filterData}
            //],
            // dataTreeExpandElement:expandEl, //assign element as expand element
            dataTreeStartExpanded:true,
            movableRows:false,
            clipboardPasteAction:function(rowData){
                return this.table.addData(rows);
            },
            rowContextMenu: rowMenu, //add context menu to rows
            // initialFilter:[
            //     {field:"Name", type:"like", value:this.filterData}
            // ],
            resizableColumns:false,
            selectable:true,
            data:dataMap,
            pagination:"local",
            paginationSize:20,
            responsiveLayout:"collapse",
            columns:[
                {title:"Name",   field:"Name", headerMenu:headerMenu ,headerFilter:true, formatter:function(cell, formatterParams){
                        var value = cell.getValue();
										//console.log ('Cell ID : ' + sfdcURL+'/'+cell.getRow().getData().Id);
                        if (cell.getRow().getData().Id === recordIdTemp)
                            return "<span style='color:#c29304;font-weight:normal;'>" + value + "</span>";
                        return "<span style='color:#000000; font-weight:normal;'><a href='" +  sfdcURL + "/" + cell.getRow().getData().Id + "'>" + value + "</a></span>";
                    }},
                {title:"AccountStatus",   field:"RC_Account_Status__c",headerMenu:headerMenu , formatter:function(cell, formatterParams){
                        var value = cell.getValue();
                        if (value === undefined)
                        	return "<span style='color:#000000; font-weight:normal;'>" + "" + "</span>";
                        return "<span style ='color:#000000; font-weight:normal;'>" + value + "</span>";
                    }},
                {title:"RecordType",   field:"RecordType.Name",headerMenu:headerMenu , formatter:function(cell, formatterParams){
                        var value = cell.getValue();
                        if (value === undefined)
                        	return "<span style='color:#000000; font-weight:normal;'>" + "" + "</span>";
                        return "<span style='color:#000000; font-weight:normal;'>" + value + "</span>";
                    }},
                {title:"Sector",   field:"Sector__c",headerMenu:headerMenu , formatter:function(cell, formatterParams){
                        var value = cell.getValue();
											  if (value === undefined)
                        	return "<span style='color:#000000; font-weight:normal;'>" + "" + "</span>";
                        return "<span style='color:#000000; font-weight:normal;'>" + value + "</span>";
                    }},
                {title:"SegmentName",   field:"Segment_Name__r.Name", editor:"input",headerMenu:headerMenu , formatter:function(cell, formatterParams){
                    var value = cell.getValue();
                    if (value === undefined)
                        return "<span style='color:#000000; font-weight:normal;'>" + "" + "</span>";
                    return "<span style='color:#000000; font-weight:normal;'>" + value + "</span>";
                }},
                {title:"SM Employee",   field:"SM_Employees__c", editor:"input",headerMenu:headerMenu , formatter:function(cell, formatterParams){
                    var value = cell.getValue();
                    if (value === undefined)
                        return "<span style='color:#000000; font-weight:normal;'>" + "" + "</span>";
                    return "<span style='color:#000000; font-weight:normal;'>" + value + "</span>";
                }},
                {title:"SM Country",   field:"SM_Country__c", editor:"input",headerMenu:headerMenu , formatter:function(cell, formatterParams){
                    var value = cell.getValue();
                    if (value === undefined)
                        return "<span style='color:#000000; font-weight:normal;'>" + "" + "</span>";
                    return "<span style='color:#000000; font-weight:normal;'>" + value + "</span>";
                }},
            ],
        });


    }

}