/*
 * Loads the Opportunity's tasks and events for the Opportunity Summary payload, with their
 * participants and the conversation evidence drawn from them.
 */
public with sharing class OpportunitySummaryActivityHelper {
  private static final String CONTEXT_TASK_COMPLETION = 'Task completion time query';
  private static final String CONTEXT_PARTICIPANTS = 'Activity participant loading';
  private static final String CONTEXT_TASK_RELATIONS = 'Task relation query';
  private static final String CONTEXT_EVENT_RELATIONS = 'Event relation query';
  private static final String CONTEXT_CONTACTS = 'Participant contact query';

  // Caps keep heap and callout body size in check on busy accounts.
  private static Integer activityLookbackDays {
    get {
      return OpportunitySummaryHelper.configuredInteger(
        Summary_Setting__mdt.ActivityDays__c,
        180,
        365
      );
    }
  }

  private static Integer maxActivities {
    get {
      return OpportunitySummaryHelper.configuredInteger(
        Summary_Setting__mdt.MaxActivities__c,
        50,
        50
      );
    }
  }

  private static Integer maxConversationItems {
    get {
      return OpportunitySummaryHelper.configuredInteger(
        Summary_Setting__mdt.MaxConversationItems__c,
        10,
        10
      );
    }
  }

  private static final Integer MAX_CONVERSATION_TEXT_LENGTH = 4000;
  private static final Integer MAX_ACTIVITY_RELATIONS = 250;

  @TestVisible
  private static ActivityParticipantProvider activityParticipantProvider = new ActivityParticipantProvider();

  public static ActivityData getActivityData(
    Id recordId,
    Boolean enrichmentEnabled,
    Integer recentEvidenceDays
  ) {
    Datetime windowEnd = Datetime.now();
    Datetime activitySince = windowEnd.addDays(-activityLookbackDays);
    List<SObject> tasks = GCPSummaryUtil.stripReadable(
      buildTaskQuery(recordId, activitySince).executeQuery()
    );
    Boolean tasksTruncated = OpportunitySummaryPayloadHelper.trimOverflow(
      tasks,
      maxActivities
    );
    Map<Id, Datetime> taskCompletionTimesById = loadTaskCompletionTimes(tasks);
    Boolean taskCompletionTimesLoaded = taskCompletionTimesById != null;
    if (!taskCompletionTimesLoaded) {
      taskCompletionTimesById = new Map<Id, Datetime>();
    }

    // QueryFactory cannot validate Owner.Name on Event — Owner is polymorphic
    // (User | Calendar) and Calendar has no Name field. Resolve User names separately.
    List<SObject> events = GCPSummaryUtil.stripReadable(
      new EventSelector()
        .selectEventsByWhatIdSinceForSummary(
          recordId,
          activitySince,
          maxActivities + 1
        )
        .executeQuery()
    );
    Boolean eventsTruncated = OpportunitySummaryPayloadHelper.trimOverflow(
      events,
      maxActivities
    );

    Set<Id> ownerIds = new Set<Id>();
    for (SObject sobj : events) {
      Id ownerId = (Id) GCPSummaryUtil.readableField(sobj, Event.OwnerId);
      if (ownerId != null && ownerId.getSObjectType() == User.SObjectType) {
        ownerIds.add(ownerId);
      }
    }

    Map<Id, String> ownerNamesById = new Map<Id, String>();
    if (!ownerIds.isEmpty()) {
      for (
        SObject sobj : GCPSummaryUtil.stripReadable(
          new UserSelector().selectUsersByIds(ownerIds).executeQuery()
        )
      ) {
        Id userId = (Id) GCPSummaryUtil.readableField(sobj, User.Id);
        String userName = (String) GCPSummaryUtil.readableField(
          sobj,
          User.Name
        );
        if (userId != null) {
          ownerNamesById.put(userId, userName);
        }
      }
    }

    ActivityData data = assembleActivityData(
      tasks,
      events,
      ownerNamesById,
      taskCompletionTimesById,
      enrichmentEnabled,
      activitySince,
      windowEnd,
      recentEvidenceDays,
      tasksTruncated,
      eventsTruncated
    );
    if (!taskCompletionTimesLoaded) {
      data.conversationReasonCode = 'task_completion_time_retrieval_error';
      if (data.conversations.isEmpty()) {
        data.conversationStatus = 'error';
      }
    }
    data.tasksAccessible = Task.SObjectType.getDescribe().isAccessible();
    data.eventsAccessible = Event.SObjectType.getDescribe().isAccessible();
    return data;
  }

  @TestVisible
  private static QueryFactory buildTaskQuery(
    Id recordId,
    Datetime activitySince
  ) {
    return new TaskSelector()
      .selectTasksByWhatIdSinceForOpportunitySummary(
        recordId,
        activitySince,
        maxActivities + 1
      );
  }

  @TestVisible
  private static Map<Id, Datetime> loadTaskCompletionTimes(
    List<SObject> tasks
  ) {
    Set<Id> taskIds = new Set<Id>();
    for (SObject taskRecord : tasks) {
      Id taskId = (Id) GCPSummaryUtil.readableField(taskRecord, Task.Id);
      if (taskId != null) {
        taskIds.add(taskId);
      }
    }
    if (taskIds.isEmpty()) {
      return new Map<Id, Datetime>();
    }

    try {
      List<SObject> completionRows = GCPSummaryUtil.stripReadable(
        new TaskSelector().selectTaskCompletionTimesByIds(taskIds)
      );
      Map<Id, Datetime> completionTimesByTaskId = new Map<Id, Datetime>();
      for (SObject completionRow : completionRows) {
        completionTimesByTaskId.put(
          (Id) GCPSummaryUtil.readableField(completionRow, Task.Id),
          (Datetime) GCPSummaryUtil.readableField(
            completionRow,
            Task.CompletedDateTime
          )
        );
      }
      return completionTimesByTaskId;
    } catch (QueryException e) {
      // Conversation evidence is optional; preserve the established activity payload.
      OpportunitySummaryHelper.recordFailure(CONTEXT_TASK_COMPLETION, e);
      return null;
    }
  }

  @TestVisible
  private static ActivityData assembleActivityData(
    List<SObject> tasks,
    List<SObject> events,
    Map<Id, String> eventOwnerNamesById,
    Boolean enrichmentEnabled,
    Datetime activityWindowStart,
    Datetime windowEnd,
    Integer recentEvidenceDays,
    Boolean tasksTruncated,
    Boolean eventsTruncated
  ) {
    return assembleActivityData(
      tasks,
      events,
      eventOwnerNamesById,
      new Map<Id, Datetime>(),
      enrichmentEnabled,
      activityWindowStart,
      windowEnd,
      recentEvidenceDays,
      tasksTruncated,
      eventsTruncated
    );
  }

  private static ActivityData assembleActivityData(
    List<SObject> tasks,
    List<SObject> events,
    Map<Id, String> eventOwnerNamesById,
    Map<Id, Datetime> taskCompletionTimesById,
    Boolean enrichmentEnabled,
    Datetime activityWindowStart,
    Datetime windowEnd,
    Integer recentEvidenceDays,
    Boolean tasksTruncated,
    Boolean eventsTruncated
  ) {
    ActivityData data = new ActivityData();
    data.activityWindowStart = activityWindowStart;
    data.activityWindowEnd = windowEnd;
    data.conversationWindowStart = windowEnd.addDays(-recentEvidenceDays);
    data.tasksTruncated = tasksTruncated;
    data.eventsTruncated = eventsTruncated;

    // Participants decide which activities qualify as conversation evidence, so
    // they load on every request; they are added to activity rows only with enrichment.
    ActivityParticipantResult participantResult = new ActivityParticipantResult();
    try {
      participantResult = activityParticipantProvider.load(tasks, events);
    } catch (Exception e) {
      OpportunitySummaryHelper.recordFailure(CONTEXT_PARTICIPANTS, e);
      participantResult.status = 'error';
      participantResult.reasonCode = 'participant_retrieval_error';
    }
    data.participantStatus = participantResult.status;
    data.participantReasonCode = participantResult.reasonCode;
    data.participantRelationsTruncated = participantResult.isTruncated;

    for (SObject sobj : tasks) {
      Task taskRecord = (Task) sobj;
      SObject owner = OpportunitySummaryPayloadHelper.readableRelated(
        taskRecord,
        OpportunitySummaryPayloadHelper.RELATIONSHIP_OWNER
      );
      Map<String, Object> row = new Map<String, Object>{
        'id' => GCPSummaryUtil.readableField(taskRecord, Task.Id),
        'subject' => GCPSummaryUtil.readableField(taskRecord, Task.Subject),
        'status' => GCPSummaryUtil.readableField(taskRecord, Task.Status),
        'type' => GCPSummaryUtil.readableField(taskRecord, Task.Type),
        'activityDate' => GCPSummaryUtil.readableField(
          taskRecord,
          Task.ActivityDate
        ),
        'createdDate' => GCPSummaryUtil.readableField(
          taskRecord,
          Task.CreatedDate
        ),
        'ownerName' => GCPSummaryUtil.readableField(owner, User.Name),
        'description' => OpportunitySummaryPayloadHelper.truncateText(
          (String) GCPSummaryUtil.readableField(taskRecord, Task.Description)
        )
      };
      // TaskSubtype = 'Call' is how calls are logged; Type is usually blank.
      OpportunitySummaryPayloadHelper.putIfPresent(
        row,
        'taskSubtype',
        OpportunitySummaryPayloadHelper.normalizedText(
          GCPSummaryUtil.readableField(taskRecord, Task.TaskSubtype)
        )
      );
      if (enrichmentEnabled) {
        Id taskId = (Id) GCPSummaryUtil.readableField(taskRecord, Task.Id);
        row.put('sourceRecordId', taskId);
        row.put('participants', participantsFor(participantResult, taskId));
      }
      data.tasks.add(row);
    }

    for (SObject sobj : events) {
      Event eventRecord = (Event) sobj;
      Id ownerId = (Id) GCPSummaryUtil.readableField(
        eventRecord,
        Event.OwnerId
      );
      Map<String, Object> row = new Map<String, Object>{
        'id' => GCPSummaryUtil.readableField(eventRecord, Event.Id),
        'subject' => GCPSummaryUtil.readableField(eventRecord, Event.Subject),
        'startDateTime' => GCPSummaryUtil.readableField(
          eventRecord,
          Event.StartDateTime
        ),
        'endDateTime' => GCPSummaryUtil.readableField(
          eventRecord,
          Event.EndDateTime
        ),
        'createdDate' => GCPSummaryUtil.readableField(
          eventRecord,
          Event.CreatedDate
        ),
        'ownerName' => eventOwnerNamesById.get(ownerId),
        'description' => OpportunitySummaryPayloadHelper.truncateText(
          (String) GCPSummaryUtil.readableField(eventRecord, Event.Description)
        )
      };
      if (enrichmentEnabled) {
        Id eventId = (Id) GCPSummaryUtil.readableField(eventRecord, Event.Id);
        row.put('sourceRecordId', eventId);
        row.put('participants', participantsFor(participantResult, eventId));
      }
      data.events.add(row);
    }

    if (participantResult.status != 'error') {
      ConversationResult conversationResult = buildConversationEvidence(
        tasks,
        events,
        participantResult.participantsByActivityId,
        taskCompletionTimesById,
        data.conversationWindowStart,
        windowEnd
      );
      data.conversations = conversationResult.items;
      data.conversationsTruncated =
        conversationResult.isTruncated || participantResult.isTruncated;
      data.conversationReasonCode = participantResult.isTruncated
        ? 'participant_relation_limit'
        : conversationResult.reasonCode;
    } else {
      data.conversationStatus = 'error';
      data.conversationReasonCode = 'participant_retrieval_error';
    }

    return data;
  }

  public virtual class ActivityParticipantProvider {
    public virtual ActivityParticipantResult load(
      List<SObject> tasks,
      List<SObject> events
    ) {
      List<SObject> taskRelations = new List<SObject>();
      List<SObject> eventRelations = new List<SObject>();
      Set<Id> taskIds = recordIds(tasks);
      Set<Id> eventIds = recordIds(events);
      List<String> unavailableSources = new List<String>();
      Boolean relationsTruncated = false;

      if (!taskIds.isEmpty()) {
        if (TaskRelation.SObjectType.getDescribe().isAccessible()) {
          try {
            taskRelations = GCPSummaryUtil.stripReadable(
              new TaskRelationSelector()
                .selectWhoRelationsByTaskIds(
                  taskIds,
                  MAX_ACTIVITY_RELATIONS + 1
                )
                .executeQuery()
            );
            if (
              OpportunitySummaryPayloadHelper.trimOverflow(
                taskRelations,
                MAX_ACTIVITY_RELATIONS
              )
            ) {
              relationsTruncated = true;
              unavailableSources.add('task_relations_limit');
            }
          } catch (Exception e) {
            OpportunitySummaryHelper.recordFailure(CONTEXT_TASK_RELATIONS, e);
            unavailableSources.add('task_relations_error');
          }
        } else {
          unavailableSources.add('task_relations_not_accessible');
        }
      }

      if (!eventIds.isEmpty()) {
        if (EventRelation.SObjectType.getDescribe().isAccessible()) {
          try {
            eventRelations = GCPSummaryUtil.stripReadable(
              new EventRelationSelector()
                .selectRelationsByEventIds(eventIds, MAX_ACTIVITY_RELATIONS + 1)
                .executeQuery()
            );
            if (
              OpportunitySummaryPayloadHelper.trimOverflow(
                eventRelations,
                MAX_ACTIVITY_RELATIONS
              )
            ) {
              relationsTruncated = true;
              unavailableSources.add('event_relations_limit');
            }
          } catch (Exception e) {
            OpportunitySummaryHelper.recordFailure(CONTEXT_EVENT_RELATIONS, e);
            unavailableSources.add('event_relations_error');
          }
        } else {
          unavailableSources.add('event_relations_not_accessible');
        }
      }

      List<ParticipantEvidence> evidence = collectParticipantEvidence(
        tasks,
        events,
        taskRelations,
        eventRelations
      );
      Set<Id> contactIds = new Set<Id>();
      for (ParticipantEvidence item : evidence) {
        contactIds.add(item.contactId);
      }

      ActivityParticipantResult result = new ActivityParticipantResult();
      result.isTruncated = relationsTruncated;
      if (!unavailableSources.isEmpty()) {
        result.reasonCode = unavailableSources.size() == 1
          ? unavailableSources[0]
          : 'participant_sources_partial';
      }
      if (contactIds.isEmpty()) {
        return result;
      }
      if (!Contact.SObjectType.getDescribe().isAccessible()) {
        result.status = 'not_accessible';
        result.reasonCode = 'contacts_not_accessible';
        return result;
      }

      try {
        List<SObject> contacts = GCPSummaryUtil.stripReadable(
          new ContactSelector()
            .selectContactNamesByIds(contactIds)
            .executeQuery()
        );
        result.participantsByActivityId = materializeParticipants(
          evidence,
          contacts
        );
        return result;
      } catch (Exception e) {
        OpportunitySummaryHelper.recordFailure(CONTEXT_CONTACTS, e);
        result.status = 'error';
        result.reasonCode = 'contact_retrieval_error';
        return result;
      }
    }
  }

  @TestVisible
  private static List<ParticipantEvidence> collectParticipantEvidence(
    List<SObject> tasks,
    List<SObject> events,
    List<SObject> taskRelations,
    List<SObject> eventRelations
  ) {
    Map<String, ParticipantEvidence> evidenceByKey = new Map<String, ParticipantEvidence>();

    for (SObject record : tasks) {
      addParticipantEvidence(
        evidenceByKey,
        (Id) GCPSummaryUtil.readableField(record, Task.Id),
        contactId(GCPSummaryUtil.readableField(record, Task.WhoId)),
        'unknown',
        'Task.WhoId contact link'
      );
    }
    for (SObject record : events) {
      addParticipantEvidence(
        evidenceByKey,
        (Id) GCPSummaryUtil.readableField(record, Event.Id),
        contactId(GCPSummaryUtil.readableField(record, Event.WhoId)),
        'unknown',
        'Event.WhoId contact link'
      );
    }
    for (SObject record : taskRelations) {
      addParticipantEvidence(
        evidenceByKey,
        (Id) GCPSummaryUtil.readableField(record, TaskRelation.TaskId),
        contactId(
          GCPSummaryUtil.readableField(record, TaskRelation.RelationId)
        ),
        'unknown',
        'TaskRelation.RelationId contact link'
      );
    }
    for (SObject record : eventRelations) {
      Boolean isInvitee = (Boolean) GCPSummaryUtil.readableField(
        record,
        EventRelation.IsInvitee
      );
      addParticipantEvidence(
        evidenceByKey,
        (Id) GCPSummaryUtil.readableField(record, EventRelation.EventId),
        contactId(
          GCPSummaryUtil.readableField(record, EventRelation.RelationId)
        ),
        isInvitee == true ? 'invited' : 'unknown',
        isInvitee == true
          ? 'EventRelation invitee record'
          : 'EventRelation.RelationId contact link'
      );
    }
    return evidenceByKey.values();
  }

  private static void addParticipantEvidence(
    Map<String, ParticipantEvidence> evidenceByKey,
    Id activityId,
    Id contactRecordId,
    String participationStatus,
    String evidenceSource
  ) {
    if (activityId == null || contactRecordId == null) {
      return;
    }
    String key =
      String.valueOf(activityId) +
      ':' +
      String.valueOf(contactRecordId);
    ParticipantEvidence existing = evidenceByKey.get(key);
    if (existing == null) {
      evidenceByKey.put(
        key,
        new ParticipantEvidence(
          activityId,
          contactRecordId,
          participationStatus,
          evidenceSource
        )
      );
    } else if (
      existing.participationStatus == 'unknown' &&
      participationStatus == 'invited'
    ) {
      existing.participationStatus = participationStatus;
      existing.evidenceSource = evidenceSource;
    }
  }

  @TestVisible
  private static Map<Id, List<Map<String, Object>>> materializeParticipants(
    List<ParticipantEvidence> evidence,
    List<SObject> contacts
  ) {
    Map<Id, SObject> contactsById = new Map<Id, SObject>();
    for (SObject contactRecord : contacts) {
      Id contactRecordId = (Id) GCPSummaryUtil.readableField(
        contactRecord,
        Contact.Id
      );
      if (contactRecordId != null) {
        contactsById.put(contactRecordId, contactRecord);
      }
    }

    Map<Id, List<Map<String, Object>>> participantsByActivityId = new Map<Id, List<Map<String, Object>>>();
    for (ParticipantEvidence item : evidence) {
      SObject contactRecord = contactsById.get(item.contactId);
      if (contactRecord == null) {
        continue;
      }
      Map<String, Object> participant = new Map<String, Object>{
        'contactId' => item.contactId,
        'participationStatus' => item.participationStatus,
        'evidenceSource' => item.evidenceSource
      };
      OpportunitySummaryPayloadHelper.putIfPresent(
        participant,
        'name',
        GCPSummaryUtil.readableField(contactRecord, Contact.Name)
      );
      OpportunitySummaryPayloadHelper.putIfPresent(
        participant,
        'title',
        GCPSummaryUtil.readableField(contactRecord, Contact.Title)
      );
      if (!participantsByActivityId.containsKey(item.activityId)) {
        participantsByActivityId.put(
          item.activityId,
          new List<Map<String, Object>>()
        );
      }
      participantsByActivityId.get(item.activityId).add(participant);
    }
    return participantsByActivityId;
  }

  @TestVisible
  private static ConversationResult buildConversationEvidence(
    List<SObject> tasks,
    List<SObject> events,
    Map<Id, List<Map<String, Object>>> participantsByActivityId,
    Datetime windowStart,
    Datetime windowEnd
  ) {
    return buildConversationEvidence(
      tasks,
      events,
      participantsByActivityId,
      new Map<Id, Datetime>(),
      windowStart,
      windowEnd
    );
  }

  private static ConversationResult buildConversationEvidence(
    List<SObject> tasks,
    List<SObject> events,
    Map<Id, List<Map<String, Object>>> participantsByActivityId,
    Map<Id, Datetime> taskCompletionTimesById,
    Datetime windowStart,
    Datetime windowEnd
  ) {
    List<ConversationCandidate> candidates = new List<ConversationCandidate>();
    Set<Id> seenActivityIds = new Set<Id>();

    for (SObject record : tasks) {
      Id activityId = (Id) GCPSummaryUtil.readableField(record, Task.Id);
      Datetime occurredAt = taskCompletionTimesById.get(activityId);
      if (occurredAt == null) {
        occurredAt = (Datetime) GCPSummaryUtil.readableField(
          record,
          Task.CompletedDateTime
        );
      }
      Boolean isClosed = (Boolean) GCPSummaryUtil.readableField(
        record,
        Task.IsClosed
      );
      addConversationCandidate(
        candidates,
        seenActivityIds,
        activityId,
        occurredAt,
        (String) GCPSummaryUtil.readableField(record, Task.Description),
        'Task',
        isClosed == true,
        participantsByActivityId,
        windowStart,
        windowEnd
      );
    }
    for (SObject record : events) {
      Id activityId = (Id) GCPSummaryUtil.readableField(record, Event.Id);
      Datetime occurredAt = (Datetime) GCPSummaryUtil.readableField(
        record,
        Event.StartDateTime
      );
      Datetime endedAt = (Datetime) GCPSummaryUtil.readableField(
        record,
        Event.EndDateTime
      );
      addConversationCandidate(
        candidates,
        seenActivityIds,
        activityId,
        occurredAt,
        (String) GCPSummaryUtil.readableField(record, Event.Description),
        'Event',
        endedAt != null && endedAt <= windowEnd,
        participantsByActivityId,
        windowStart,
        windowEnd
      );
    }

    candidates.sort();
    ConversationResult result = new ConversationResult();
    Boolean textWasTruncated = false;
    for (Integer i = 0; i < candidates.size(); i++) {
      if (i >= maxConversationItems) {
        result.isTruncated = true;
        break;
      }
      result.items.add(candidates[i].item);
      if ((Boolean) candidates[i].item.get('isTruncated') == true) {
        textWasTruncated = true;
      }
    }
    result.isTruncated = result.isTruncated || textWasTruncated;
    if (candidates.size() > maxConversationItems && textWasTruncated) {
      result.reasonCode = 'item_and_text_limits';
    } else if (candidates.size() > maxConversationItems) {
      result.reasonCode = 'item_limit';
    } else if (textWasTruncated) {
      result.reasonCode = 'text_limit';
    } else if (result.items.isEmpty()) {
      result.reasonCode = 'transcripts_not_supported_no_recent_notes';
    } else {
      result.reasonCode = 'activity_notes_only';
    }
    return result;
  }

  private static void addConversationCandidate(
    List<ConversationCandidate> candidates,
    Set<Id> seenActivityIds,
    Id activityId,
    Datetime occurredAt,
    String text,
    String sourceType,
    Boolean activityCompleted,
    Map<Id, List<Map<String, Object>>> participantsByActivityId,
    Datetime windowStart,
    Datetime windowEnd
  ) {
    List<Map<String, Object>> participants = participantsByActivityId.get(
      activityId
    );
    if (
      activityId == null ||
      seenActivityIds.contains(activityId) ||
      occurredAt == null ||
      occurredAt < windowStart ||
      occurredAt > windowEnd ||
      String.isBlank(text) ||
      activityCompleted != true ||
      participants == null ||
      participants.isEmpty()
    ) {
      return;
    }

    seenActivityIds.add(activityId);
    Boolean isTruncated = text.length() > MAX_CONVERSATION_TEXT_LENGTH;
    String boundedText = isTruncated
      ? text.left(MAX_CONVERSATION_TEXT_LENGTH)
      : text;
    Map<String, Object> item = new Map<String, Object>{
      'sourceRecordId' => activityId,
      'relatedActivityId' => activityId,
      'occurredAt' => occurredAt,
      'sourceType' => sourceType,
      'contentType' => 'notes',
      'text' => boundedText,
      'participants' => participants,
      'isTruncated' => isTruncated
    };
    candidates.add(new ConversationCandidate(occurredAt, item));
  }

  private static Set<Id> recordIds(List<SObject> records) {
    Set<Id> ids = new Set<Id>();
    for (SObject record : records) {
      Id recordId = (Id) record.Id;
      if (recordId != null) {
        ids.add(recordId);
      }
    }
    return ids;
  }

  private static Id contactId(Object possibleId) {
    if (possibleId == null) {
      return null;
    }
    try {
      Id candidate = (Id) possibleId;
      return candidate.getSObjectType() == Contact.SObjectType
        ? candidate
        : null;
    } catch (Exception ignored) {
      // Relation and Who Ids can point at Leads or carry non-Id values; only Contacts count.
      return null;
    }
  }

  private static List<Map<String, Object>> participantsFor(
    ActivityParticipantResult result,
    Id activityId
  ) {
    List<Map<String, Object>> participants = result.participantsByActivityId.get(
      activityId
    );
    return participants == null
      ? new List<Map<String, Object>>()
      : participants;
  }

  public class ActivityData {
    public List<Map<String, Object>> tasks = new List<Map<String, Object>>();
    public List<Map<String, Object>> events = new List<Map<String, Object>>();
    public List<Map<String, Object>> conversations = new List<Map<String, Object>>();
    public Boolean tasksTruncated = false;
    public Boolean eventsTruncated = false;
    public Boolean conversationsTruncated = false;
    public Boolean participantRelationsTruncated = false;
    public Boolean tasksAccessible = true;
    public Boolean eventsAccessible = true;
    public String participantStatus = 'available';
    public String participantReasonCode;
    public String conversationStatus;
    public String conversationReasonCode;
    public Datetime activityWindowStart;
    public Datetime activityWindowEnd;
    public Datetime conversationWindowStart;
  }

  public class ActivityParticipantResult {
    public Map<Id, List<Map<String, Object>>> participantsByActivityId = new Map<Id, List<Map<String, Object>>>();
    public String status = 'available';
    public String reasonCode;
    public Boolean isTruncated = false;
  }

  public class ParticipantEvidence {
    public Id activityId;
    public Id contactId;
    public String participationStatus;
    public String evidenceSource;

    public ParticipantEvidence(
      Id activityId,
      Id contactId,
      String participationStatus,
      String evidenceSource
    ) {
      this.activityId = activityId;
      this.contactId = contactId;
      this.participationStatus = participationStatus;
      this.evidenceSource = evidenceSource;
    }
  }

  public class ConversationResult {
    public List<Map<String, Object>> items = new List<Map<String, Object>>();
    public Boolean isTruncated = false;
    public String reasonCode;
  }

  private class ConversationCandidate implements Comparable {
    private Datetime occurredAt;
    private Map<String, Object> item;

    private ConversationCandidate(
      Datetime occurredAt,
      Map<String, Object> item
    ) {
      this.occurredAt = occurredAt;
      this.item = item;
    }

    public Integer compareTo(Object other) {
      ConversationCandidate otherCandidate = (ConversationCandidate) other;
      if (occurredAt == otherCandidate.occurredAt) {
        return 0;
      }
      return occurredAt > otherCandidate.occurredAt ? -1 : 1;
    }
  }
}
