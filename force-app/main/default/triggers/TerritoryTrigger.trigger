trigger TerritoryTrigger on Territory__c (before insert, before update, after update, before delete) {
    if (Trigger.isInsert && Trigger.isBefore) {
        TerritoryTriggerHandler.onBeforeInsert(Trigger.new);
    }
    if (Trigger.isUpdate && Trigger.isBefore) {
        TerritoryTriggerHandler.onBeforeUpdate(Trigger.new);
    }
    if (Trigger.isUpdate && Trigger.isAfter) {
        if (!TerritoryManagmentUtility.callFromDeleteTriggerContext) {
            TerritoryTriggerHandler.onAfterUpdate(Trigger.old,Trigger.new);
        }
    }
    if (Trigger.isDelete && Trigger.isBefore) {
        TerritoryTriggerHandler.onBeforeDelete(Trigger.old);
    }
}