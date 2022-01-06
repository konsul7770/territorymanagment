public with sharing class TerrUserTriggerHandler {

    private static final String USER_NOT_DEFINED = 'User Field can\' be empty';
    private static final String TERRITORY_NOT_DEFINED = 'Territory field can\' be empty';
    public class FindChild{
        public Territory__c rootTerritory;
        public List<FindChild> childrenTerritories;
   
        
        public FindChild(Territory__c parentTerritory){
            this.rootTerritory = parentTerritory;
            this.childrenTerritories = new List<FindChild>();
        }
        
    }

    public static void onBeforeInsert(List<TerrUser__c> terrUserObjectsList) {
        insertNewShare(terrUserObjectsList);
    }

    public static void onBeforeUpdate(List<TerrUser__c> oldTerrUserObjectsList,List<TerrUser__c> newTerrUserObjectsList) {
        deleteOldShare(oldTerrUserObjectsList);
        insertNewShare(newTerrUserObjectsList);
    }

    public static void onAfterDelete(Map<Id,TerrUser__c> terrUserForDeleteObjects) {
        Set<Id> oldUserIds = new Set<Id>();
        Set<Id> territoriesIds = new Set<Id>();
        for (TerrUser__c terrUser : terrUserForDeleteObjects.values()) {
            oldUserIds.add(terrUser.User__c);
            territoriesIds.add(terrUser.Territory__c);
        }

        Map<Id,TerrUser__c> notDeletedTerrUserObjects = new Map<Id,TerrUser__c>([
            SELECT Id,Name, Territory__c, User__c
            FROM TerrUser__c
            WHERE User__c IN :oldUserIds
        ]);
        List<TerrUser__c> deletedTerrUserObjects = new List<TerrUser__c>();
        if (!notDeletedTerrUserObjects.isEmpty()) {
            Map<Id,Territory__c> territoryMap = new Map<Id,Territory__c>([
                SELECT Id, Name, Territory__c FROM Territory__c
            ]);
            Boolean parentExits = false;
            Integer userCoinsidence = 0;
            for (TerrUser__c deletedTerrUser : terrUserForDeleteObjects.values()) {
                Id curId = territoryMap.get(deletedTerrUser.Territory__c).Id;
                while (curId != null) {
                    for (TerrUser__c notDeletedTerrUser : notDeletedTerrUserObjects.values()) {
                        if (deletedTerrUser.User__c == notDeletedTerrUser.User__c ) {
                            userCoinsidence++;
                            if (curId == notDeletedTerrUser.Territory__c) {
                                parentExits = true;
                            }
                        }
                    }
                    curId = territoryMap.get(curId).Territory__c;
                }
                if (!parentExits || userCoinsidence == 0) {
                    deletedTerrUserObjects.add(deletedTerrUser);
                } else {
                    parentExits = false;
                    userCoinsidence = 0;
                }
            }
            terrUserForDeleteObjects.clear();
            terrUserForDeleteObjects.putAll(deletedTerrUserObjects);
        }
        deleteOldShare(terrUserForDeleteObjects.values());
    }
    
    private static Map<Id,Set<Id>> getHierarchy(Set<Id> territoryIds) {
        FindChild rootNode;
        Map<Id,Set<Id>> stepsMap = new Map<Id,Set<Id>>();
        Map<Id, Territory__c> territoryMap = new Map<Id, Territory__c>([SELECT Id, Name, Territory__c FROM Territory__c]);
        
        Map<Id, FindChild> nodesMap = new Map<Id, FindChild>();
        
        for (Id territoryId : territoryIds) {
            rootNode = new FindChild(territoryMap.get(territoryId));
            nodesMap.put(territoryId, rootNode);
    
            FindChild currentNode;
            FindChild parentTerritory;
            for(Territory__c currentTerritory :territoryMap.values()){
                
                if(!nodesMap.containsKey(currentTerritory.Id)){
                    nodesMap.put(currentTerritory.Id, new FindChild(currentTerritory));
                }
    
                currentNode = nodesMap.get(currentTerritory.Id);
    
                if(!nodesMap.containsKey(currentTerritory.Territory__c)){
                    nodesMap.put(currentTerritory.Territory__c, new FindChild(territoryMap.get(currentTerritory.Territory__c)));
                }
    
                parentTerritory = nodesMap.get(currentTerritory.Territory__c);
                parentTerritory.childrenTerritories.add(currentNode);
            }
            stepsMap.put(territoryId,createSteps(rootNode));
            nodesMap.clear();
        }
        return stepsMap;
    }
    private static Map<Id,List<Account>> getAccountsForChildrenTerritories(Map<Id,Set<Id>> stepsMap) {
        //TODO: good select implementation
        Map<Id,List<Account>> accountsForEachTerritory = new Map<Id,List<Account>>();
        Set<Id> allTerritoryIds = new Set<Id>();
        for (Set<Id> st : stepsMap.values()) {
            allTerritoryIds.addAll(st);
        }
        List<Account> accounts = [
            SELECT
                Id,
                Name,
                Territory__c,
                (SELECT Contact__c FROM Reference__r)
            FROM
                Account
            WHERE Territory__c IN :allTerritoryIds
        ];
        
        for (Id key : stepsMap.keySet()) {
            List<Account> accountsForMap = new List<Account>();
            for (Id terId : stepsMap.get(key)) {
                for (Account accont : accounts) {
                    if (accont.Territory__c == terId) {
                        accountsForMap.add(accont);
                    }
                }
            }
            
            accountsForEachTerritory.put(key, accountsForMap);
        }
        return accountsForEachTerritory;
    }
    private static Set<Id> createSteps(FindChild root) {
        Set<Id> steps = new Set<Id>();
        getSteps(root,steps);
        return steps;
    }
    private static void getSteps(FindChild root, Set<Id> steps){
        //TODO: need check rootTerritory for null value
        if(root.rootTerritory == null) {
            return;
        }
        steps.add(root.rootTerritory.Id);
        if (! root.childrenTerritories.isEmpty()) {
            for (FindChild child : root.childrenTerritories) {
                getSteps(child,steps);
            }
        }
    }
    private static void deleteOldShare(List<TerrUser__c> oldTerrUserObjectsList) {
        Set<Id> oldUserIds = new Set<Id>();
        Set<Id> oldTerritoriesIds = new Set<Id>();
        for (TerrUser__c terrUser : oldTerrUserObjectsList) {
            oldUserIds.add(terrUser.User__c);
            oldTerritoriesIds.add(terrUser.Territory__c);
        }
        Map<Id,Set<Id>> oldHierarchy = getHierarchy(oldTerritoriesIds);
        Map<Id,List<Account>> oldAccountsForShare = getAccountsForChildrenTerritories(oldHierarchy);
        Set<Id> oldAccountIds = new Set<Id>();
        Set<Id> oldContactIds = new Set<Id>();
        for (List<Account> accountList : oldAccountsForShare.values()) {
            for (Account accont : accountList) {
                oldAccountIds.add(accont.Id);
                for (Reference__c ref : accont.Reference__r) {
                    oldContactIds.add(ref.Contact__c);
                }
            }
        }

        List<AccountShare> oldAccountShareObjects = TerritoryManagmentUtility.getAccountsShareObjects(oldUserIds,oldAccountIds);
        List<ContactShare> oldContactShareObjects = TerritoryManagmentUtility.getContactsShareObjects(oldUserIds, oldContactIds);
        List<AccountShare> accountShareForDelete = new List<AccountShare>();
        List<ContactShare> contactShareForDelete = new List<ContactShare>();
        for (TerrUser__c terrUser : oldTerrUserObjectsList) {
            for (Account accont : oldAccountsForShare.get(terrUser.Territory__c)) {
                for (AccountShare acShare : oldAccountShareObjects) {
                    if (acShare.AccountId == accont.Id && acShare.UserOrGroupId == terrUser.User__c) {
                        accountShareForDelete.add(acShare);
                        for (Reference__c ref : accont.Reference__r) {
                            for (ContactShare contShare : oldContactShareObjects) {
                                if (ref.Contact__c == contShare.ContactId && contShare.UserOrGroupId == terrUser.User__c) {
                                    contactShareForDelete.add(contShare);
                                }
                            }
                        }
                    }
                }
            }
        }

        try {
            delete accountShareForDelete;
            delete contactShareForDelete;
        } catch (Exception e) {
            system.debug(e.getMessage());
        }
    }
    private static void insertNewShare(List<TerrUser__c> newTerrUserObjectsList) {
        Set<Id> territoriesIds = new Set<Id>();
        for (TerrUser__c terrUser : newTerrUserObjectsList) {
            territoriesIds.add(terrUser.Territory__c);
        }
        Map<Id,Set<Id>> hierarchy = getHierarchy(territoriesIds);
        Map<Id,List<Account>> accountsForShare = getAccountsForChildrenTerritories(hierarchy);
        List<AccountShare> accountsShare = new List<AccountShare>();
        List<ContactShare> contactsShare = new List<ContactShare>();
        for (TerrUser__c terrUser : newTerrUserObjectsList) {
            if (terrUser.User__c == null) {
                terrUser.User__c.addError(USER_NOT_DEFINED);
            }
            if (terrUser.Territory__c == null) {
                terrUser.Territory__c.addError(TERRITORY_NOT_DEFINED);
            }
            for (Account accont : accountsForShare.get(terrUser.Territory__c)) {
                AccountShare acShare = new AccountShare();
                acShare.AccountId = accont.Id;
                acShare.UserOrGroupId = terrUser.User__c;
                acShare.AccountAccessLevel = 'edit';
                acShare.OpportunityAccessLevel = 'edit';
                acShare.RowCause = Schema.AccountShare.RowCause.Manual;
                accountsShare.add(acShare);
                if (!accont.Reference__r.isEmpty()) {
                    for (Reference__c ref : accont.Reference__r) {
                        ContactShare contShare = new ContactShare();
                        contShare.ContactId = ref.Contact__c;
                        contShare.UserOrGroupId = terrUser.User__c;
                        contShare.ContactAccessLevel = 'edit';
                        contShare.RowCause = Schema.ContactShare.RowCause.Manual;
                        contactsShare.add(contShare);
                    }
                }
            } 
        }
        
        try {
            insert accountsShare;
            insert contactsShare;
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
    }
}