public with sharing class TerritoryTriggerHandler {
    private static final String PARENT_WITH_THE_SAME_NAME = 'There is a parent record with the same name';
    private static final String THE_SAME_TERRITORY = 'There is already exist territory with such a name on the same hierarchy';
    private static final String THE_SAME_CHILD_TERRITORY = 'There is already exist a child record with the same Name';

    public static void onBeforeInsert(List<Territory__c> territories) {
        
        Set<String> territoryNames = new Set<String>();
        for (Territory__c ter : territories) {
            territoryNames.add(ter.Name);
        }

        Map<Id,Territory__c> territoryListForNames = new Map<Id,Territory__c>([
            SELECT
                    Id,
                    Name,
                    Territory__c,
                    Territory__r.Name
            FROM
                    Territory__c
            WHERE
                    Name IN :territoryNames
        ]);
        for (Territory__c territory : territories) {
            if (territoryListForNames.ContainsKey(territory.Territory__c)) {
                if (territory.Name == territoryListForNames.get(territory.Territory__c).Name) {
                    territory.Name.addError(PARENT_WITH_THE_SAME_NAME);
                }
            }
            for (Territory__c ter : territoryListForNames.values()) {
                if (territory.Territory__c == ter.Territory__c && territory.Name == ter.Name) {
                    territory.Name.addError(THE_SAME_TERRITORY);
                }
                if (territory.Territory__c == null && ter.Territory__c == null && territory.Name == ter.Name) {
                    territory.Name.addError(THE_SAME_TERRITORY);
                }
            }
        }
    }

    public static void onBeforeUpdate(List<Territory__c> territories) {
        Set<String> territoryNames = new Set<String>();
        for (Territory__c ter : territories) {
            territoryNames.add(ter.Name);
        }

        Map<Id,Territory__c> territoryListForNames = new Map<Id,Territory__c>([
            SELECT
                    Id,
                    Name,
                    Territory__c,
                    Territory__r.Name
            FROM
                    Territory__c
            WHERE
                    Name IN :territoryNames
        ]);
        for (Territory__c territory : territories) {
            if (territoryListForNames.ContainsKey(territory.Territory__c)) {
                if (territory.Name == territoryListForNames.get(territory.Territory__c).Name) {
                    territory.Name.addError(PARENT_WITH_THE_SAME_NAME);
                }
            }
            for (Territory__c ter : territoryListForNames.values()) {
                if (territory.Territory__c == ter.Territory__c && territory.Name == ter.Name) {
                    territory.Name.addError(THE_SAME_TERRITORY);
                }
                if (territory.Territory__c == null && ter.Territory__c == null && territory.Name == ter.Name) {
                    territory.Name.addError(THE_SAME_TERRITORY);
                }
                if (territory.Id == ter.Territory__c && territory.Name == ter.Name) {
                    territory.Name.addError(THE_SAME_CHILD_TERRITORY);
                }
            }
        }
    }
    public static void onAfterUpdate(List<Territory__c> oldTerritoryObjects, List<Territory__c> newTerritoryObjects) {
        Set<Id> oldParent = new Set<Id>();
        for (Territory__c oldTerritory : oldTerritoryObjects) {
            for (Territory__c newTerritory : newTerritoryObjects) {
                if (oldTerritory.Id == newTerritory.Id && oldTerritory.Territory__c != newTerritory.Territory__c) {
                    oldParent.add(oldTerritory.Id);
                }
            }
        }
        List<Account> accounts = [
            SELECT Id, Name, Territory__c, (SELECT Contact__c FROM Reference__r) FROM Account 
            WHERE Territory__c IN : oldParent Limit 1];
        Set<Id> accountIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        for (Account accont : accounts) {
            accountIds.add(accont.Id);
            for (Reference__c ref : accont.Reference__r) {
                contactIds.add(ref.Contact__c);
            }
        }
        List<AccountShare> accountShareList = [select Id, AccountId, UserOrGroupId ,AccountAccessLevel ,RowCause from AccountShare where AccountId IN :accountIds AND RowCause = 'Manual'];
        List<ContactShare> contactShareList = [select Id, ContactId, UserOrGroupId ,ContactAccessLevel ,RowCause from ContactShare where ContactId IN :contactIds AND RowCause = 'Manual'];
        
        try {
            delete accountShareList;
            delete contactShareList;
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
    }
    public static void onBeforeDelete(List<Territory__c> territories) {
        Set<Id> deletingTerritories = new Set<Id>();
        for (Territory__c ter : territories) {
            deletingTerritories.add(ter.Id);
        }
        List<Account> accountsDeletingTerritories = [
            SELECT Id, Territory__c
            FROM Account
            WHERE Territory__c IN :deletingTerritories
        ];
        List<Territory__c> childrenTerritories = [
            SELECT Id, Name, Territory__c
            FROM Territory__c
            WHERE Territory__c IN :deletingTerritories
        ];
        List<Territory__c> territoriesForUpdate = new List<Territory__c>();
        for (Territory__c territory : territories) {
            for (Territory__c childTerritory: childrenTerritories) {
                if (childTerritory.Territory__c == territory.Id) {
                    childTerritory.Territory__c = territory.Territory__c;
                    territoriesForUpdate.add(childTerritory);
                    for (Account accont : accountsDeletingTerritories) {
                        if (accont.Territory__c == territory.Id) {
                            accont.Territory__c = territory.Territory__c;
                        }
                    }
                }
            }
        }
        TerritoryManagmentUtility.callFromDeleteTriggerContext = true;
        try {
            update territoriesForUpdate;
            update accountsDeletingTerritories;
        } catch (Exception e) {
            System.debug(e.getMessage());
        } finally{
            TerritoryManagmentUtility.callFromDeleteTriggerContext = false;
        }
    }
}
