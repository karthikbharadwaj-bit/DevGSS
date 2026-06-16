/*
* Name         : LiveChatTranscriptTrigger.trigger
* Created By   : Crisanto de Llamas (crisanto.dellamas@ringcentral.com)
* Created Date : 03/Oct/2016
* Description  : This trigger will
*					1) Create a Lead record once a Sales Chat request is abandoned by the guest.
*                   	Logic: IF  Status = Missed and
*                              Transcript Body = Empty and
*                              Deployment = UK or US Sales Chat
*                       Create a Lead with Lead Source = 'Lead Initial Chat'
*					2) Save Survey result and assign lead to chat transcript using chat key
* Dependencies : No
*
* Modified: This trigger works not for snapins live chat deployment
*/

trigger LiveChatTranscriptTrigger on LiveChatTranscript (after insert, after update,before update) {
	new Triggers()
            .bind(Triggers.Evt.afterinsert, new LiveChatTranscriptHandler.LiveChatTranscriptAfter())
            .bind(Triggers.Evt.afterupdate, new LiveChatTranscriptHandler.LiveChatTranscriptAfter())
            //CRM-5077 - Added as Part of EU Data Privacy Project to restrict changing the Owner when the Record is of EU
			//.bind(Triggers.Evt.beforeupdate, new LiveChatTranscriptHandler.CheckEUDataPrivacy()) Commented as a part of ITPMO-3741

			.manage();
}