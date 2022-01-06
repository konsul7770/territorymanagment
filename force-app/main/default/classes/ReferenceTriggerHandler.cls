public with sharing class ReferenceTriggerHandler {
    public static void onBeforeInsert(List<Reference__c> references) {
        Set<Id> accountsIds = new Set<Id>();
        for (Reference__c ref : references) {
            accountsIds.add(ref.Account__c);
        }
        List<AccountShare> accountShare = getAccountsShare(accountsIds);
        List<ContactShare> contactsShare = new List<ContactShare>();
        for (Reference__c ref : references) {
            for (AccountShare accontShare : accountShare) {
                if (ref.Account__c == accontShare.AccountId) {
                    ContactShare contShare = new ContactShare();
                    contShare.ContactId = ref.Contact__c;
                    contShare.UserOrGroupId = accontShare.UserOrGroupId;
                    contShare.ContactAccessLevel = 'edit';
                    contShare.RowCause = Schema.ContactShare.RowCause.MANUAL;
                    contactsShare.add(contShare);
                }
            }
        }
        try {
            insert contactsShare;
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
    }
    public static void onAfterUpdate(List<Reference__c> oldRefs, List<Reference__c> newRefs) {
        Set<Id> accountsIds = new Set<Id>();
        Set<Id> contactsIds = new Set<Id>();
        for (Reference__c ref : oldRefs) {
            accountsIds.add(ref.Account__c);
            contactsIds.add(ref.Contact__c);
        }
        List<AccountShare> oldAccountShare = getAccountsShare(accountsIds);
        Set<Id> oldUserIds = new Set<Id>();
        for (AccountShare acShare : oldAccountShare) {
            oldUserIds.add(acShare.UserOrGroupId);
        }
        List<ContactShare> oldContactShare = TerritoryManagmentUtility.getContactsShareObjects(oldUserIds,contactsIds);
        List<ContactShare> contactShareForDelete = new List<ContactShare>();
        for (Reference__c oldRef : oldRefs) {
            for (AccountShare acShare : oldAccountShare) {
                if (oldRef.Account__c == acShare.AccountId) {
                    for (ContactShare contShare : oldContactShare) {
                        if (contShare.ContactId == oldRef.Contact__c && acShare.UserOrGroupId == contShare.UserOrGroupId && acShare.RowCause == 'Manual' && contShare.RowCause == 'Manual') {
                            contactShareForDelete.add(contShare);
                        }
                    }
                }
            }
        }
        try {
            delete contactShareForDelete;
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
        Set<Id> newAccountsIds = new Set<Id>();
        Set<Id> newContactsIds = new Set<Id>();
        for (Reference__c ref : newRefs) {
            newAccountsIds.add(ref.Account__c);
            newContactsIds.add(ref.Contact__c);
        }
        List<AccountShare> newAccountShare = getAccountsShare(newAccountsIds);
        List<ContactShare> newContactShare = new List<ContactShare>();
        for (Reference__c newRef : newRefs) {
            for (AccountShare acShare : newAccountShare) {
                if (newRef.Account__c == acShare.AccountId) {
                    ContactShare contShare = new ContactShare();
                    contShare.ContactId = newRef.Contact__c;
                    contShare.UserOrGroupId = acShare.UserOrGroupId;
                    contShare.ContactAccessLevel = 'edit';
                    contShare.RowCause = Schema.ContactShare.RowCause.MANUAL;
                    newContactShare.add(contShare);
                }
            }
        }
        
        try {
            insert newContactShare;
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
    }
    public static void onAfterDelete(List<Reference__c> references) {
        Set<Id> accountsIds = new Set<Id>();
        Set<Id> contactsIds = new Set<Id>();
        for (Reference__c ref : references) {
            accountsIds.add(ref.Account__c);
            contactsIds.add(ref.Contact__c);
        }
        List<AccountShare> accountsShare = getAccountsShare(accountsIds);
        Set<Id> userIds = new Set<Id>();
        for (AccountShare acShare : accountsShare) {
            userIds.add(acShare.UserOrGroupId);
        }
        
        List<ContactShare> contactsShare = TerritoryManagmentUtility.getContactsShareObjects(userIds,contactsIds);
        List<ContactShare> contactsShareForDelete = new List<ContactShare>();
        for (Reference__c Ref : references) {
            for (AccountShare acShare : accountsShare) {
                if (ref.Account__c == acShare.AccountId) {
                    for (ContactShare contShare : contactsShare) {
                        if (contShare.ContactId == ref.Contact__c && acShare.UserOrGroupId == contShare.UserOrGroupId && acShare.RowCause == 'Manual' && contShare.RowCause == 'Manual') {
                            contactsShareForDelete.add(contShare);
                        }
                    }
                }
            }
        }

        try {
            delete contactsShareForDelete;
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
        List<Reference__c> existedReferences = [
            SELECT Id, Account__c, Contact__c
            FROM Reference__c
            WHERE Contact__c IN :contactsIds
        ];
        Set<Id> newAccountIds = new Set<Id>();
        for (Reference__c ref : existedReferences) {
            newAccountIds.add(ref.Account__c);
        }
        List<AccountShare> accountShareForAccountExistedRefs = [
            SELECT Id, AccountId, AccountAccessLevel, UserOrGroupId, RowCause
            FROM AccountShare
            WHERE AccountId IN :newAccountIds AND RowCause = 'Manual'
        ];
        List<ContactShare> contactShareForInsert = new List<ContactShare>();
        for (Reference__c ref : existedReferences) {
            for (AccountShare acShare : accountShareForAccountExistedRefs) {
                if (ref.Account__c == acShare.AccountId && contactsIds.contains(ref.Contact__c)) {
                    ContactShare contShare = new ContactShare();
                    contShare.ContactId = ref.Contact__c;
                    contShare.UserOrGroupId = acShare.UserOrGroupId;
                    contShare.ContactAccessLevel = 'edit';
                    contShare.RowCause = Schema.ContactShare.RowCause.MANUAL;
                    contactShareForInsert.add(contShare);
                }
            }
        }
        
        try {
            insert contactShareForInsert;
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
    }

    private static List<AccountShare> getAccountsShare(Set<Id> accountsIds) {
        List<AccountShare> accountsShare = [
            SELECT Id, AccountId, UserOrGroupId, AccountAccessLevel, RowCause FROM AccountShare 
            WHERE AccountId IN :accountsIds AND RowCause = :Schema.AccountShare.RowCause.MANUAL];
        return accountsShare;
    }
}
