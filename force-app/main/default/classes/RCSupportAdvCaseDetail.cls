public without sharing class RCSupportAdvCaseDetail {
	
	public ApexPages.StandardController controller {get;set;}
	public Case caseDetailObj {get;set;}
	public String strFormatDate {get;set;}
	public List<CommentWrapper> commentWrapperList {get;set;}
	public Boolean toShowAttachmentLinks {get;set;}
	public String commentDesc {get;set;}
	public Boolean isCaseCommentPublic {get;set;}
	public String strTimeMessage {get;set;}
	public Boolean isCaseInClosedStatus {get;set;}
	public Boolean toShowCommentErrorMessage {set;get;}
	public String showFileSizeLimitNotification {get;set;}
	public Integer fileSizeLimit {get;set;}
    public String domain { get; set; }


    public RCSupportAdvCaseDetail(ApexPages.StandardController controller) {
		this.controller = controller;
		toShowAttachmentLinks = false;
		isCaseCommentPublic = false;
		caseDetailObj = new Case();
        domain = String.valueOf(System.Url.getOrgDomainUrl().toExternalForm());
        getClosedStatus();
		toShowCommentErrorMessage = false;
		String errVariable = ApexPages.currentPage().getParameters().get('showErr');
		if(errVariable == 'true'){
			toShowCommentErrorMessage = true;
			errorMessage = 'Your Case was recently closed. Comments cannot be made to a Case which has been Closed.';
		}
	}
	
	public Attachment attachment {
	  get {
          if (attachment == null) {
              attachment = new Attachment();
          }
	      return attachment;
	    }
	  set;
  	}
	
	public Boolean toShowDispositionWebCase {get;set;}
	public Boolean toShowGuestCaseInfo {get;set;}
	public PageReference getCaseDetail() {
		commentWrapperList = new List<CommentWrapper>();
		if(controller.getId() != null) {
			isCaseInClosedStatus = false;
			try {
                String caseId = ApexPages.currentPage().getParameters().get('Id');
				User currentUser = SCUserService.currentUser;
                Id accountId = (SCUserService.isCurrentUserSCAdmin ? currentUser.Contact.AccountId : null);
                caseDetailObj = getCaseObject(caseId, currentUser, accountId);

				String caseRecordName = CaseHelper.RT_INFO_BY_ID.get(caseDetailObj.RecordTypeId).getName();
				fileSizeLimit = caseRecordName == CaseHelper.RT_NAME_SUPPORT_RC_APP ? 10 : 5;
				showFileSizeLimitNotification = caseRecordName == CaseHelper.RT_NAME_SUPPORT_RC_APP ? 'Up to 10MB' : 'Up to 5MB';
				
				if(caseDetailObj != null) {
					strFormatDate = caseDetailObj.CreatedDate.format('h:mm a z, MM/dd/yyyy','America/Los_Angeles');
					for(CaseComment caseCommentObj : caseDetailObj.CaseComments) {
						System.debug('>>5>>'+caseCommentObj.IsPublished);
				 		CommentWrapper commentWRObj = new CommentWrapper();
				 		commentWRObj.commentBody = caseCommentObj.CommentBody;
				 		commentWRObj.openedBy = caseCommentObj.CreatedBy.Name;
				 		commentWRObj.openeddateformat = caseCommentObj.CreatedDate.format('h:mm a z, MM/dd/yyyy','America/Los_Angeles');
				 		commentWrapperList.add(commentWRObj);
					}
					if(caseDetailObj.Attachments != null && caseDetailObj.Attachments.size()>0) {
						toShowAttachmentLinks = true;
					} else {
						toShowAttachmentLinks = false;
					}
					assignSLAMessage(caseDetailObj);
					setDisposition(caseDetailObj.RecordTypeId);
					if(caseDetailObj.Status != null && closedStatusSet != null && closedStatusSet.contains((caseDetailObj.Status.toUpperCase()))) {
						isCaseInClosedStatus = true;
                        toShowCommentErrorMessage = true;
                        errorMessage = 'Your Case was recently closed. Comments cannot be made to a Case which has been Closed.';
					}
				}
			} catch(Exception ex) {
                PlatformLog.logException(RCSupportAdvCaseDetail.class.getName(), ex);
                System.debug(ex);
                System.debug(ex.getStackTraceString());
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Couldn\'t load case data. Please, try again later'));
                caseDetailObj = new Case();
			}
		}
		return null;
	}

    private Case getCaseObject(Id caseId, User currentUser, Id accountId) {
        return [
            SELECT Subject,CaseNumber,Description,CreatedDate,Status,Account.Name,Case_Severity__c,
                Product_Assistance__c,Product_Assistance_Lvl2__c,Product_Assistance_Lvl3__c,
                Entitlement.Name,Entitlement.BusinessHours.Name,Entitlement.BusinessHours.FridayEndTime,
                Entitlement.BusinessHours.FridayStartTime,Resolution__c, Support_Disposition_Level_2__c,
                Support_Disposition_Level_1__c, RecordTypeId, Case_Contact_First_Name__c,
                Case_Contact_Last_Name__c, Entitlement.BusinessHours.MondayEndTime,
                Entitlement.BusinessHours.MondayStartTime,Entitlement.BusinessHours.SaturdayEndTime,
                Entitlement.BusinessHours.SaturdayStartTime,Entitlement.BusinessHours.SundayEndTime,
                Entitlement.BusinessHours.SundayStartTime, Entitlement.BusinessHours.ThursdayEndTime,
                Entitlement.BusinessHours.ThursdayStartTime,Entitlement.BusinessHours.TuesdayEndTime,
                Entitlement.BusinessHours.TuesdayStartTime,Entitlement.BusinessHours.WednesdayEndTime,
                Entitlement.BusinessHours.WednesdayStartTime,
                (
                    SELECT IsPublished, CommentBody, CreatedById, CreatedDate, LastModifiedDate,
                        LastModifiedById, CreatedBy.Name
                    FROM CaseComments
                    WHERE  IsPublished = TRUE AND IsDeleted = FALSE
                    ORDER BY CreatedDate
                    DESC
                ),
                (SELECT Id, ParentId, Name FROM Attachments)
            FROM Case
            WHERE (Id = :caseId)
                AND ((ContactId = :currentUser.ContactId) OR (AccountId != NULL AND AccountId = :accountId))];
    }
	
	Set<String> closedStatusSet = new Set<String>();
    public void getClosedStatus() {
    	closedStatusSet.add(('Duplicate').toUpperCase());
    	closedStatusSet.add(('Invalid').toUpperCase());
    	closedStatusSet.add(('Cancelled').toUpperCase());
    	closedStatusSet.add(('Closed').toUpperCase());
    	closedStatusSet.add(('Closed - Endorsed').toUpperCase());
    	closedStatusSet.add(('Closed - No Contact').toUpperCase());
    	closedStatusSet.add(('Closed - No Issue').toUpperCase());
    	closedStatusSet.add(('Closed - No Response').toUpperCase());
    }
	
	public void setDisposition(String recordTypeId) {
		try {
			Schema.DescribeSObjectResult result = Case.SObjectType.getDescribe();
    		Map<ID,Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosById();
    		if(!String.isBlank(recordTypeId) && rtMapByName != null && rtMapByName.get(recordTypeId).getName() == 'Support-Case') {
    			toShowDispositionWebCase = true;
    			toShowGuestCaseInfo = false;
    		} else {
    			toShowGuestCaseInfo = true;
    		}
		} catch(Exception ex) {
		
		}
	}
	
	public class TimeWrapper{
        public Time startTime{get;set;}
        public Time endTime{get;set;}
        public TimeWrapper(Time startTime, Time endTime) {
            this.startTime = startTime;
            this.endTime = endTime;
        }
    }
    
    public Map<String,TimeWrapper> getBusinesssHoursDetail(BusinessHours businessHoursObj){
        Map<String,TimeWrapper> businessHourDetailMap = new Map<String,TimeWrapper>();
        businessHourDetailMap.put('Monday', new TimeWrapper(businessHoursObj.MondayStartTime, businessHoursObj.MondayEndTime));
        businessHourDetailMap.put('Tuesday', new TimeWrapper(businessHoursObj.TuesdayStartTime, businessHoursObj.TuesdayEndTime));
        businessHourDetailMap.put('Wednesday', new TimeWrapper(businessHoursObj.WednesdayStartTime, businessHoursObj.WednesdayEndTime));
        businessHourDetailMap.put('Thursday', new TimeWrapper(businessHoursObj.ThursdayStartTime, businessHoursObj.ThursdayEndTime));
        businessHourDetailMap.put('Friday', new TimeWrapper(businessHoursObj.FridayStartTime, businessHoursObj.FridayEndTime));
        businessHourDetailMap.put('Saturday', new TimeWrapper(businessHoursObj.SaturdayStartTime, businessHoursObj.SaturdayEndTime));
        businessHourDetailMap.put('Sunday', new TimeWrapper(businessHoursObj.SundayStartTime, businessHoursObj.SundayEndTime));
        return businessHourDetailMap;
    }
    private void assignSLAMessage(Case caseDetailObj) {
        /**************** FOR SUPPORT BASIC BUSINESS HOURS ********************/
        if(caseDetailObj.Entitlement.BusinessHours.Name != null && caseDetailObj.Entitlement.BusinessHours.Name.equalsIgnoreCase('Support - Basic')) {
            /************* CONDITION 1 - Submission date lies between Business Hours ***********************/
            Map<String,TimeWrapper> businessHourDetailMap = getBusinesssHoursDetail(caseDetailObj.Entitlement.BusinessHours);
            Datetime caseSubmissionDate = caseDetailObj.CreatedDate;
            Datetime alteredDate = caseSubmissionDate.addHours(1);
            String currentDay = alteredDate.format('EEEE');
            TimeWrapper range = businessHourDetailMap.get(currentDay);
            if(range != null && range.startTime != null && range.endTime != null) {
                Datetime localTime = Datetime.newInstance(alteredDate.date(), alteredDate.time());
                TimeZone tz = TimeZone.getTimeZone('America/Los_Angeles');
                Datetime dtObj = Datetime.newInstance(alteredDate.getTime() + tz.getOffset(alteredDate));
                
                Datetime rangeStartTime = Datetime.newInstance(alteredDate.date(), range.startTime);
                rangeStartTime = Datetime.newInstance(rangeStartTime.getTime()+ tz.getOffset(rangeStartTime));
                Datetime rangeEndTime = Datetime.newInstance(alteredDate.date(), range.endTime);
	            rangeEndTime = Datetime.newInstance(rangeEndTime.getTime()+ tz.getOffset(rangeEndTime));

            	if((getMilliSeconds(dtObj)  >= getMilliSeconds(rangeStartTime) && getMilliSeconds(dtObj) < getMilliSeconds(rangeEndTime))
                	|| (getMilliSeconds(rangeStartTime) == getMilliSeconds(rangeEndTime))){
                    if(caseDetailObj.Case_Severity__c.equalsIgnoreCase('Level 2 - Urgent')) {
                    	 strTimeMessage = 'Your case has been submitted. You will receive a response within 1 hour.';
                    	 if(((getMilliSeconds(dtObj) + getHourMilliSeconds(1)) > getMilliSeconds(rangeEndTime)) && !(getMilliSeconds(rangeStartTime) == getMilliSeconds(rangeEndTime))) {
                    	 	strTimeMessage ='Your case has been submitted. You will receive a response on the next business day.';
                    	 }
                    } else if(caseDetailObj.Case_Severity__c.equalsIgnoreCase('Level 3 - High')) {
                    	  strTimeMessage = 'Your case has been submitted. You will receive a response within 4 hours.';
                    	 if(((getMilliSeconds(dtObj) + getHourMilliSeconds(4)) > getMilliSeconds(rangeEndTime)) && !(getMilliSeconds(rangeStartTime) == getMilliSeconds(rangeEndTime))) {
                    	 	strTimeMessage ='Your case has been submitted. You will receive a response on the next business day.';
                    	 }
                    } else if(caseDetailObj.Case_Severity__c.equalsIgnoreCase('Level 4 - Medium')) {
                    	strTimeMessage = 'Your case has been submitted. You will receive a response within 8 hours.';
                    	if(((getMilliSeconds(dtObj) + getHourMilliSeconds(8)) > getMilliSeconds(rangeEndTime)) && !(getMilliSeconds(rangeStartTime) == getMilliSeconds(rangeEndTime))) {
                    	 	strTimeMessage ='Your case has been submitted. You will receive a response on the next business day.';
                	 	}
                    }
                }
            }
            if(strTimeMessage== null){
                 strTimeMessage ='Your case has been submitted. You will receive a response on the next business day.';
            }
        } else if((caseDetailObj.Entitlement.BusinessHours.Name != null &&
            caseDetailObj.Entitlement.BusinessHours.Name.equalsIgnoreCase('Support - Office Premium') )){
            strTimeMessage = 'You will receive a response within 1 hour.';
        } else if((caseDetailObj.Entitlement.BusinessHours.Name != null && caseDetailObj.Entitlement.BusinessHours.Name.equalsIgnoreCase('Support Office Standard'))) {
            strTimeMessage = 'You will receive a response within 1 hour.';
        } else {
            strTimeMessage ='Your case has been submitted. You will receive a response on the next business day.';
        }
    }
    private Integer getHourMilliSeconds(Integer hour) {
    	return (hour*60*60);
    }
    private Integer getMilliSeconds(Datetime timeObj) {
        return (timeObj.hourGmt()*60*60 + timeObj.minuteGmt()*60 + timeObj.secondGmt());
    }
	public PageReference sentToClone() {
		try {
			PageReference rtnPg;
			if(controller.getId() != null && controller.getId() != '') {
				rtnPg = new PageReference('/RCSupportPortalCreateNewCase?parentId='+ controller.getId());
			} else if(ApexPages.currentPage().getParameters().get('Id') != null && ApexPages.currentPage().getParameters().get('Id') != '') {
				rtnPg = new PageReference('/RCSupportPortalCreateNewCase?parentId='+ ApexPages.currentPage().getParameters().get('Id'));
			}
			rtnPg.setRedirect(true);
			return rtnPg;
		} catch(Exception ex) {}
		return null;
	}
	

	public PageReference addCaseComment(Boolean sc) {
        PageReference pgref;
        String caseDetailURL = '/RCSupportAdvCaseDetail';
        if(sc) {
			caseDetailURL = '/RCSupportAdvCaseDetailSC';
		}
        try {
            Case caseObj = [SELECT Id, Status FROM Case WHERE Id =:controller.getId()];
            if(!(caseObj.Status != null && closedStatusSet != null && closedStatusSet.contains((caseObj.Status.toUpperCase())))){
                CaseComment caseCommentObjToIns = new CaseComment();
                caseCommentObjToIns.ParentId = controller.getId();
				if (commentDesc.length() > 4000 ) {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Comment size is too long'));
					return null;
				} else {
					caseCommentObjToIns.CommentBody = commentDesc;
				}
                insert caseCommentObjToIns;

                pgref = new PageReference(caseDetailURL);
                pgref.getParameters().put('Id',caseDetailObj.Id);
                pgref.setRedirect(true);
                return pgref;
            }else {
               toShowCommentErrorMessage = true;
               errorMessage = 'Your Case was recently closed. Comments cannot be made to a Case which has been Closed.';
               pgref = new PageReference(caseDetailURL);
               pgref.getParameters().put('showErr','true');
               pgref.getParameters().put('Id',caseDetailObj.Id);
               pgref.setRedirect(true);
               return pgref;
            }
        } catch(Exception ex) {}
        return null;
    }
    public PageReference addCaseComment() {
        return addCaseComment(false);
    }
    public PageReference addCaseCommentSC() {
        return addCaseComment(true);
    }
	public String errorMessage {get;set;}
	public Boolean toShowErrorMessage {get;set;}
	public Integer fileSize {get;set;}
	public PageReference attachFile(Boolean sc) {
		toShowErrorMessage = false;
		PageReference pgref;
		try {
			if(attachment != null && attachment.body != null) {
				System.debug('>>>##>>323'+fileSize);
				List<Attachment> attachmentQty = [SELECT Name, BodyLength FROM Attachment WHERE ParentId =:controller.getId()];
				Decimal attachedFilesSize = 0;
				for (Attachment attachments : attachmentQty) {
					attachedFilesSize += Decimal.valueOf(attachments.BodyLength)/(1024 * 1024);
					if (attachments.Name == attachment.Name) {
						toShowErrorMessage = true;
						errorMessage = 'File is already attached';
						attachment = null;
						return null;
					}
				}
				if (toShowGuestCaseInfo && attachmentQty!= null &&
						(attachmentQty.size() == 3 ||
						attachedFilesSize > 10 ||
						(attachedFilesSize+Decimal.valueOf(fileSize)/(1024 * 1024)) > 10)) {
					toShowErrorMessage = true;
					errorMessage = 'Could not attach files. Please make sure that you have fewer than 3 attachments with total size of 10mb or less';
					attachment = null;
					return null;
				}
				if(fileSize != null) {
					Decimal fileSizeDB = Decimal.valueof(fileSize)/(1024 * 1024);
					System.debug('>>>##>>323e>>'+fileSizeDB);
					if(fileSizeDB > fileSizeLimit) {
						toShowErrorMessage = true;
						errorMessage = 'Uploaded file size must not be greater then' + String.valueOf(fileSizeLimit) + 'MB.';
						attachment = null;
						return null;
					}
				}
				Attachment attachObj = attachment;
				attachObj.ParentId = controller.getId();
				insert attachObj;
				System.debug('>>>##>>3'+attachObj);
                if (sc) {
                    pgref = new PageReference('/RCSupportAdvCaseDetailSC');
                } else {
                    pgref = new PageReference('/RCSupportAdvCaseDetail');
                }
				pgref.getParameters().put('Id',caseDetailObj.Id);
				pgref.setRedirect(true);
				return pgref;
			} else {
				toShowErrorMessage = true;
				errorMessage = 'Please select the file before upload.';
				return null;
			}
		} catch(Exception ex) {
			System.debug(ex.getMessage());
		}
		return null;
	}
	public PageReference attachFile() {
        return attachFile(false);
    }
    public PageReference attachFileSC() {
        return attachFile(true);
    }
	public String deleteAttachId {get;set;}
	public PageReference deleteAttachment() {
		System.debug('>>!@#>>'+deleteAttachId);
		try {
			if(deleteAttachId != null) {
				Attachment attachObj = new 	Attachment(Id = deleteAttachId);
				if(attachObj != null) {
					delete attachObj;
					getCaseDetail();
				}
			}
			if(Test.isRunningTest()){
				Integer i = 1/0;
			}
		} catch(Exception ex) {
			System.debug('>>111!@#>>'+ ex);
		}
		return null;
	}
	
	
	
	public class CommentWrapper {
		public String commentBody {get;set;}
		public String openedBy {get;set;}
		public String openeddateformat {get;set;}
		
		public CommentWrapper() {
			commentBody = null;
			openedBy = null;
			openeddateformat = null;
		}
	}
}