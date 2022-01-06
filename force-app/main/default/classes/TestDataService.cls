@isTest
public with sharing class TestDataService {
    // todo rename `get` to `create`
    public static User createUserForTest(String ComNicknameAndUsername) {

        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name='TerritoryUser' LIMIT 1 ];

        User u = new user();
        u.LastName = 'Test Code1';
        u.Email = 'test@test.com';
        u.Alias = 'Tcode';
        u.Username = ComNicknameAndUsername;
        u.CommunityNickname = ComNicknameAndUsername;
        u.LocaleSidKey = 'en_US';
        u.TimeZoneSidKey = 'GMT';
        u.ProfileID = profiles[0].id;
        u.LanguageLocaleKey = 'en_US';
        u.EmailEncodingKey = 'UTF-8';

        insert u;

        return u;
    }
//    public static Territory__c getTerritoryForTest (String name,Territory__c territory) {
//        Territory__c terr = new Territory__c(Name=name,Territory__c=territory.id);
//        insert terr;
//        return terr;
//    }
    public static Territory__c createTerritoryForTest(String name,Id territory) {
        Territory__c terr = new Territory__c(Name=name,Territory__c=territory);
        insert terr;
        return terr;
    }
    public static Territory__c createTerritoryForTest(String name) {
        Territory__c terr = new Territory__c(Name=name);
        insert terr;
        return terr;
    }
    public static  TerrUser__c createTerrUserForTest(String name,Id territory,Id user){
        TerrUser__c terUser = new TerrUser__c (Name=name,Territory__c=territory,User__c=user);
        insert terUser;
        return terUser;
    }
    public static  List<Account> createAccountsWithTerritoryForTest(Integer countAccounts,String name,Id territory) {
        List <Account> accounts = new List<Account>();
        for(Integer i=0;i<countAccounts;i++) {
            Account acc = new Account();
            acc.Name = i+name;
            acc.Territory__c = territory;
            accounts.add(acc);
        }
        insert accounts;
        return accounts;
    }
    public static  List<Contact> createContactsForTest(Integer countContacts,String lastName) {
        List <Contact> contacts = new List<Contact>();
        for(Integer i=0;i<countContacts;i++) {
            Contact cont = new Contact();
            cont.LastName = lastName;
            contacts.add(cont);
        }
        insert contacts;
        return contacts;
    }
    public static Reference__c createReferenceForTest(String name,Account acc,Contact cont) {
        Reference__c ref = new Reference__c (Name=name,Account__c=acc.Id,Contact__c=cont.Id);
        insert ref;
        return ref;
    }
    public static List<User> createUsersForTest(Integer countUsers,String ComNicknameAndUsername) {

        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name='TerritoryUser' LIMIT 1 ];

        List<User> users = new List<User>();

        for(Integer i=0;i<countUsers;i++) {
            User u = new user();
            u.LastName = i+'Test Code1';
            u.Email = 'test@test.com';
            u.Alias = i+'Tcode';
            u.Username = i+ComNicknameAndUsername;
            u.CommunityNickname = i+ComNicknameAndUsername;
            u.LocaleSidKey = 'en_US';
            u.TimeZoneSidKey = 'GMT';
            u.ProfileID = profiles[0].id;
            u.LanguageLocaleKey = 'en_US';
            u.EmailEncodingKey = 'UTF-8';
            users.add(u);
        }

        insert users;

        return users;
    }
}