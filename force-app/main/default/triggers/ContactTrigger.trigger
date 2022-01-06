trigger ContactTrigger on Contact (before insert) {
    if (Trigger.isInsert && Trigger.isBefore) {
        ContactTriggerHandler.onBeforeInsert(Trigger.new);
    }
}