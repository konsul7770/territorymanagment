trigger ReferenceTrigger on Reference__c (before insert,after update, after delete) {
    if (Trigger.isInsert && Trigger.isBefore) {
        ReferenceTriggerHandler.onBeforeInsert(Trigger.new);
    }
    if (Trigger.isUpdate && Trigger.isAfter) {
        ReferenceTriggerHandler.onAfterUpdate(Trigger.old, Trigger.new);
    }
    if (Trigger.isDelete) {
        ReferenceTriggerHandler.onAfterDelete(Trigger.old);
    }
}