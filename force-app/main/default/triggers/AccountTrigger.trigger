trigger AccountTrigger on Account (after insert, before update) {
    if (Trigger.isInsert && Trigger.isAfter) {
        AccountTriggerHandler.onAfterInsert(Trigger.new);
    }
    if (Trigger.isUpdate && Trigger.isBefore) {
        AccountTriggerHandler.onBeforeUpdate(Trigger.oldMap, Trigger.newMap);
    }
}