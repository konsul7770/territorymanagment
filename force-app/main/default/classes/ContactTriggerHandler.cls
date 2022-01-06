public with sharing class ContactTriggerHandler {
    public static void onBeforeInsert(List<Contact> contacts) {
        List<Account> accList = [SELECT Id, Name FROM Account WHERE Name ='DummyAccount' LIMIT 1];
        if (accList.isEmpty()) {
            accList.add(new Account(Name = 'DummyAccount'));
            insert accList;
        } 
             
        for (Contact cont : contacts) {
            if (cont.AccountId == null) {
                cont.AccountId = accList[0].Id;
            }
        }
    }
}
