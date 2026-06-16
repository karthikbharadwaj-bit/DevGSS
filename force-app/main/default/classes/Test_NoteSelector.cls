@isTest
private class Test_NoteSelector {
    //Lead fields defined
    private static final String LEAD_FIRST_NAME = 'Test';
    private static final String LEAD_LAST_NAME = 'Test';
    private static final String LEAD_EMAIL = 'testlead@test.com';

    //Note fields defined
    private static final String NOTE_BODY = 'Body';
    private static final String NOTE_TITLE = 'Title';

    //Assert messages defined
    private static final String ASSERT_MESSAGE = 'Notes should be selected';
    private static final String ASSERT_EQUALS_MESSAGE = 'Wring note selected';

    @testSetup
    private static void testData(){
        Lead testLead = (Lead) new SObjectBuilder(Lead.SobjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.FirstName => LEAD_FIRST_NAME,
                    Lead.LastName => LEAD_LAST_NAME,
                    Lead.Email => LEAD_EMAIL
                }
            )
            .create()
            .getRecord();
        
        Note testNote = (Note) new SObjectBuilder(Note.SobjectType)
            .setFields(
                new Map<SObjectField, Object>{
                   Note.ParentId => testLead.Id,
                   Note.Body => NOTE_BODY, 
                   Note.Title => NOTE_TITLE
                }
            )
            .create()
            .getRecord();
    }
    
    @isTest
    private static void testSelectNotes(){
        List<Note> notes = (List<Note>) new NoteSelector(true, true)
            .selectNotes()
            .executeQuery();
        
        System.assert(notes.size() > 0, ASSERT_MESSAGE);
    }
    
    @isTest
    private static void testSelectNotesForLeadConvert(){
        List<Note> notes = (List<Note>) new NoteSelector()
            .selectNotes()
            .executeQuery();
        
        List<Note> notesForLeadConvert = (List<Note>) new NoteSelector()
            .selectNotesForLeadConvert(new List<Object>{notes[0].ParentId})
            .executeQuery();
        
        System.assert(notesForLeadConvert.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(notes[0].Id, notesForLeadConvert[0].Id, ASSERT_EQUALS_MESSAGE);
    }
}