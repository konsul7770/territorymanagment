public with sharing class AccountTriggerHandler {
    public static void onAfterInsert(List<Account> accounts) {
        Set<Id> territoryIds = new Set<Id>();
        for (Account accont : accounts) {
            territoryIds.add(accont.Territory__c);
        }
        Map<Id,Set<Id>> hierarchyMap = territoryHierarchyBuild(territoryIds);
        Map<Id,TerrUser__c> terrUsersMap = getTerrUsers(hierarchyMap);
        List<AccountShare> accountsShare = new List<AccountShare>();
        for (Account accont : accounts) {
            for (Id terrId : hierarchyMap.get(accont.Territory__c)) {
                for (TerrUser__c terrUser : terrUsersMap.values()) {
                    if (terrUser.Territory__c == terrId) {
                        AccountShare acShare = new AccountShare();
                        acShare.AccountId = accont.Id;
                        acShare.UserOrGroupId = terrUser.User__c;
                        acShare.AccountAccessLevel = 'edit';
                        acShare.OpportunityAccessLevel = 'edit';
                        acShare.RowCause = Schema.AccountShare.RowCause.Manual;
                        accountsShare.add(acShare);
                    }
                }
            }
        }
        try {
            insert accountsShare;
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
    }

    public static void onBeforeUpdate(Map<Id,Account> oldAccountsMap,Map<Id,Account> newAccountsMap) {
        
        Set<Id> oldAccountIds = new Set<Id>();
        Set<Id> oldTerritoryIds = new Set<Id>();
        for (Account accont : oldAccountsMap.values()) {
            oldAccountIds.add(accont.Id);
            oldTerritoryIds.add(accont.Territory__c);
        }
        List<AccountShare> oldAccountShare = [
            SELECT Id, AccountId, AccountAccessLevel, UserOrGroupId, RowCause
            FROM AccountShare
            WHERE AccountId IN :oldAccountIds AND RowCause = 'Manual'
        ];
        
        List<Reference__c> referencesForAccountsToContacts = [
            SELECT Account__c, Contact__c
            FROM Reference__c
            WHERE Account__c IN :oldAccountIds
        ];
        
        Set<Id> oldContactsIds = new Set<Id>();
        for (Reference__c ref : referencesForAccountsToContacts) {
            oldContactsIds.add(ref.Contact__c);
        }
        List<ContactShare> oldContactShare = [
            SELECT Id, ContactId, ContactAccessLevel, UserOrGroupId, RowCause
            FROM ContactShare
            WHERE ContactId IN :oldContactsIds AND RowCause = 'Manual'
        ];
        List<AccountShare> accountsShareForDelete = new List<AccountShare>();
        List<ContactShare> contactsShareForDelete = new List<ContactShare>();
        for (AccountShare acShare : oldAccountShare) {
            if (oldAccountsMap.containsKey(acShare.AccountId)) {
                accountsShareForDelete.add(acShare);
                for (Reference__c ref : referencesForAccountsToContacts) {
                    for (ContactShare contShare : oldContactShare) {
                        if (ref.Account__c == acShare.AccountId && ref.Contact__c == contShare.ContactId) {
                            contactsShareForDelete.add(contShare);
                        }
                    }
                }
            }
        }
        try {
            delete accountsShareForDelete;
            delete contactsShareForDelete;
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
        Set<Id> newTerritoryIds = new Set<Id>();
        for(Account accont : newAccountsMap.values()) {
            newTerritoryIds.add(accont.Territory__c);
        }
        Map<Id,Set<Id>> hierarchyForNewTerritoriesMap = territoryHierarchyBuild(newTerritoryIds);
        Map<Id,TerrUser__c> newTerrUsersMap = getTerrUsers(hierarchyForNewTerritoriesMap);
        List<AccountShare> newAccountsShare = new List<AccountShare>();
        List<ContactShare> newContactsShare = new List<ContactShare>();
        
        for (Account accont : newAccountsMap.values()) {
            for (Id terrId : hierarchyForNewTerritoriesMap.get(accont.Territory__c)) {
                for (TerrUser__c terrUser : newTerrUsersMap.values()) {
                    if (terrUser.Territory__c == terrId) {
                        AccountShare acShare = new AccountShare();
                        acShare.AccountId = accont.Id;
                        acShare.UserOrGroupId = terrUser.User__c;
                        acShare.AccountAccessLevel = 'edit';
                        acShare.OpportunityAccessLevel = 'edit';
                        acShare.RowCause = Schema.AccountShare.RowCause.Manual;
                        newAccountsShare.add(acShare);
                        for (Reference__c ref : referencesForAccountsToContacts) {
                            if (ref.Account__c == accont.Id) {
                                ContactShare contShare = new ContactShare();
                                contShare.ContactId = ref.Contact__c;
                                contShare.UserOrGroupId = terrUser.User__c;
                                contShare.ContactAccessLevel = 'edit';
                                contShare.RowCause = Schema.ContactShare.RowCause.MANUAL;
                                newContactsShare.add(contShare);
                            }
                        }
                    }
                }
            }
        }
        try {
            insert newAccountsShare;
            insert newContactsShare;
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
    }
    private static Map<Id,Set<Id>> territoryHierarchyBuild(Set<Id> territoryIds) {
        Map<Id,Territory__c> territoryMap = new Map<Id,Territory__c>([SELECT Id, Territory__c FROM Territory__c]);
        Map<Id,Set<Id>> stepsUpMap = new Map<Id,Set<Id>>();
        for (Id territoryId : territoryIds) {
            Set<Id> steps = new Set<Id>();
            Id curId = territoryId;
            while (curId != null) {
                steps.add(curId);
                curId = territoryMap.get(curId).Territory__c;
            }
            stepsUpMap.put(territoryId,steps);
        }
        return stepsUpMap;
    }
    private static Map<Id,TerrUser__c> getTerrUsers(Map<Id,Set<Id>> hierarchyMap) {
        Set<Id> allTerritoryIds = new Set<Id>();
        for (Set<Id> st : hierarchyMap.values()) {
            allTerritoryIds.addAll(st);
        }
        Map<Id,TerrUser__c> terrUserMap = new Map<Id,TerrUser__c>([SELECT Id, Territory__c, User__c FROM TerrUser__c WHERE Territory__c IN :allTerritoryIds]);
        return terrUserMap;
    }
}
