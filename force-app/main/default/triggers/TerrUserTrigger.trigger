trigger TerrUserTrigger on TerrUser__c (before insert, before update, after delete) {
    if (Trigger.isInsert && Trigger.isBefore) {
        TerrUserTriggerHandler.onBeforeInsert(Trigger.new);
    }
    if (Trigger.isUpdate && Trigger.isBefore) {
        TerrUserTriggerHandler.onBeforeUpdate(Trigger.old,Trigger.new);
    }
    if (Trigger.isDelete && Trigger.isAfter) {
        TerrUserTriggerHandler.onAfterDelete(Trigger.oldMap);
    }
}