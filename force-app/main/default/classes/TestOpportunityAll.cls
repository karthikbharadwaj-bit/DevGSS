@isTest
private class TestOpportunityAll {
    
    @isTest
    static void  myUnitTest3() {
       Opportunity objOpp1 = new Opportunity();
       list<string> lstCXDetaildetail =new list<string>{'cell Phone only','Hosted PBX','Land line','Nothing','On-Premise PBX','Other Cloud PBX',
                                                        'Traditional','Prefers not to say'};                                          
       list<string> lstCancReasons = new list<string>{'Couldn\'t get it working','Missing critical feature','Outages','QoS Voice','QoS Fax','Going out of business',
                                                      'Business slowing down / Closing location','Fewer employees','Temporary need / Testing','Too Expensive / Not worth the cost',
                                                      'Preferred number unavailable','Consolidating into other RC account','Switching devices','Not comfortable stating reason'};                                             
       list<string> lstHosted = new list<string>{'8x8','Fonality','Jive','Megapath'};   
          
       ApexPages.StandardController controller = new ApexPages.StandardController(objOpp1);
       OpportunityCancellation objOpp = new OpportunityCancellation(controller);
       objOpp.lstsectedFax.add('Distorted image') ;
       objOpp.lstsectedQOsdetail.add('Echo');
       objOpp.lstsectedCXDetaildetail = lstCXDetaildetail;
       system.assertNotEquals(objOpp.lstsectedCXDetaildetail, null);
       objOpp.lstsectedCancReasons = lstCancReasons;
       system.assertNotEquals(objOpp.lstsectedCancReasons, null);
       objOpp.lstsectedmissingfeature.add('Intercom');
       objOpp.lstselectedCouldnotworkingdetail.add('Product');
       objOpp.lstselectedNothing.add('Downsizing Company');
       objOpp.lstselectedcostDetail.add('Overall Cost'); 
       objOpp.showcompanyCall();
       objOpp.showdetailCall();      
       objOpp.lstselectedCellPhoneOnly.add('Verizon');
       objOpp.lstsectedHostedPBXdetail = lstCancReasons;
       objOpp.lstSelectedLandLine.add('Comcast');
       objOpp.lstsectedOnPremisePBXdetail.add('Barracuda');
       objOpp.lstSelectedTraditional.add('CBeyond');
       objOpp.cancel();
       objOpp.create();
       objOpp.skip();
       objOpp.Next();   
       objOpp.back();     
       objOpp.getHostedPBXOption();
       system.assertNotEquals(objOpp.getHostedPBXOption(), null);
       objOpp.getCancellationReasonOption();
       system.assertNotEquals(objOpp.getCancellationReasonOption(), null);
       objOpp.getWhichCXDetailOption();
       system.assertNotEquals(objOpp.getWhichCXDetailOption(), null);
       objOpp.getFaxOption();
       system.assertNotEquals(objOpp.getFaxOption(), null);
       objOpp.getmissingfeaturedetailOption();
       system.assertNotEquals( objOpp.getmissingfeaturedetailOption(), null);
       objOpp.getCouldnotworkingdetailOption();
       system.assertNotEquals(objOpp.getCouldnotworkingdetailOption(), null);
       objOpp.getLandLineOption();
       system.assertNotEquals(objOpp.getLandLineOption(), null);
       objOpp.getCellPhoneOnlyOption();
       system.assertNotEquals(objOpp.getCellPhoneOnlyOption(), null); 
       objOpp.getNothingOption();    
       
       ApexPages.StandardController controller1 = new ApexPages.StandardController(objOpp1);
       OpportunityCancellation testOPPObj = new OpportunityCancellation(controller1);
       testOPPObj.lstsectedCancReasons = lstCancReasons;  
       testOPPObj.Next();
       testOPPObj.getConsolidatingAccountOption();
       testOPPObj.getPriceOption();
       testOPPObj.getCustomerCareOption();
       testOPPObj.getSalesExpectationOption();
       testOPPObj.getBusinessMortality();
       testOPPObj.showOtherSubCompetitorBox();
       testOPPObj.showOtherProDetRes();
       testOPPObj.showConsolidatingAccount();
       testOPPObj.changeSubDownGrade();
       testOPPObj.getConsolidatingAccount();
       testOPPObj.getNothingListValue();
       testOPPObj.getTraditionalListValue();
       testOPPObj.getLandLineListValue();
       testOPPObj.getCellPhoneOnlyListValue();
       testOPPObj.getOnPremisePBXListValue();
       testOPPObj.getHostedPBXListValue();
       testOPPObj.getCXDetailPicListValue();
       testOPPObj.getFaxListValue();
       testOPPObj.getQOsListValue();
       testOPPObj.getMissingPicListValue();
       testOPPObj.getColuldNotPicListValue();
       testOPPObj.getCostPicListValue();
       testOPPObj.getCanCelreasonsPicListValue();
       testOPPObj.createformatDate(system.today());          
              
       ApexPages.StandardController controller3 = new ApexPages.StandardController(objOpp1);
       OpportunityCancellation testOPPObj2 = new OpportunityCancellation(controller3);
       testOPPObj2.lstsectedCancReasons = lstCancReasons;  
       testOPPObj2.Next();
       testOPPObj2.toshowerrorMsg=false;
       testOPPObj2.selectedSubCXDetail = '';
       testOPPObj2.selectedCXDetail = 'Prefers not to say';
       testOPPObj2.create();
       testOPPObj2.selectedCXDetail = 'Hosted PBX';
       testOPPObj2.create();
       testOPPObj2.selectedCXDetail = 'On-Premise PBX';
       testOPPObj2.create();
       testOPPObj2.selectedCXDetail = 'Other';
       testOPPObj2.create();
       testOPPObj2.selectedCXDetail = 'Other (provide detailed reason)';
       testOPPObj2.create();
       testOPPObj2.toshowerrorMsg=false;
       testOPPObj2.selectedCXDetail = 'Prefers not to say';
       testOPPObj2.create();
       testOPPObj2.getConsolidatingAccountOption();
       testOPPObj2.getPriceOption();
       testOPPObj2.getCustomerCareOption();
       testOPPObj2.getSalesExpectationOption();
       testOPPObj2.getBusinessMortality();
       testOPPObj2.showOtherSubCompetitorBox();
       testOPPObj2.showOtherProDetRes();
       testOPPObj2.showConsolidatingAccount();
       testOPPObj2.changeSubDownGrade();
       testOPPObj2.getConsolidatingAccount();
       testOPPObj2.getNothingListValue();
       testOPPObj2.getTraditionalListValue();
       testOPPObj2.getLandLineListValue();
       testOPPObj2.getCellPhoneOnlyListValue();
       testOPPObj2.getOnPremisePBXListValue();
       testOPPObj2.getHostedPBXListValue();
       testOPPObj2.getCXDetailPicListValue();
       testOPPObj2.getFaxListValue();
       testOPPObj2.getQOsListValue();
       testOPPObj2.getMissingPicListValue();
       testOPPObj2.getColuldNotPicListValue();
       testOPPObj2.getCostPicListValue();
       testOPPObj2.getCanCelreasonsPicListValue();
       testOPPObj2.createformatDate(system.today());          
    }
    @isTest
    static void  myUnitTest4() {
       Opportunity objOpp1 = new Opportunity();
       list<string> lstCXDetaildetail =new list<string>{'cell Phone only','Hosted PBX','Land line','Nothing','On-Premise PBX','Other Cloud PBX',
                                                        'Traditional','Prefers not to say'};                                          
       list<string> lstCancReasons = new list<string>{'Couldn\'t get it working','Missing critical feature','Outages','QoS Voice','QoS Fax','Going out of business',
                                                      'Business slowing down / Closing location','Fewer employees','Temporary need / Testing','Too Expensive / Not worth the cost',
                                                      'Preferred number unavailable','Consolidating into other RC account','Switching devices','Not comfortable stating reason'};                                             
       list<string> lstHosted = new list<string>{'8x8','Fonality','Jive','Megapath'};   
          
       ApexPages.StandardController controller = new ApexPages.StandardController(objOpp1);
       OpportunityCancellation objOpp = new OpportunityCancellation(controller);
       objOpp.lstsectedFax.add('Distorted image') ;
       objOpp.lstsectedQOsdetail.add('Echo');
       objOpp.lstsectedCXDetaildetail = lstCXDetaildetail;
       system.assertNotEquals(objOpp.lstsectedCXDetaildetail, null);
       objOpp.lstsectedCancReasons = lstCancReasons;
       system.assertNotEquals(objOpp.lstsectedCancReasons, null);
       objOpp.lstsectedmissingfeature.add('Intercom');
       objOpp.lstselectedCouldnotworkingdetail.add('Product');
       objOpp.lstselectedNothing.add('Downsizing Company');
       objOpp.lstselectedcostDetail.add('Overall Cost'); 
       objOpp.showcompanyCall();
       objOpp.showdetailCall();      
       objOpp.lstselectedCellPhoneOnly.add('Verizon');
       objOpp.lstsectedHostedPBXdetail = lstCancReasons;
       objOpp.lstSelectedLandLine.add('Comcast');
       objOpp.lstsectedOnPremisePBXdetail.add('Barracuda');
       objOpp.lstSelectedTraditional.add('CBeyond');
       objOpp.cancel();
       objOpp.create();
       objOpp.skip();
       objOpp.Next();   
       objOpp.back();     
       objOpp.getHostedPBXOption();
       objOpp.selectedCancellationRsn = 'Business Mortality';
       objOpp.finalsubDownGradeReason = '';
       objOpp.Next(); 
       objOpp.selectedCancellationRsn = 'Consolidating into other RC account';
       objOpp.finalsubDownGradeReason = '';
       objOpp.Next();
       objOpp.selectedCancellationRsn = 'Couldn\'t get it working';
       objOpp.finalsubDownGradeReason = '';
       objOpp.Next();
       objOpp.selectedCancellationRsn = 'Missing critical feature';
       objOpp.finalsubDownGradeReason = '';
       objOpp.Next();
       objOpp.selectedCancellationRsn = 'Price';
       objOpp.finalsubDownGradeReason = '';
       objOpp.Next();
       objOpp.selectedCancellationRsn = 'QoS Voice';
       objOpp.finalsubDownGradeReason = '';
       objOpp.Next();
       objOpp.selectedCancellationRsn = 'Sales Expectations';
       objOpp.finalsubDownGradeReason = '';
       objOpp.Next();
       objOpp.selectedCancellationRsn = 'Support/Customer Care';
       objOpp.finalsubDownGradeReason = '';
       objOpp.Next();
       objOpp.selectedCancellationRsn = 'Other (provide detailed reason)';
       objOpp.finalsubDownGradeReason = '';
       objOpp.Next();
    }
     
}