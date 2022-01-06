@IsTest
public with sharing class AllTestsForTerritoryManagement {
    @TestSetup
    static void setup() {
        User oldUser = TestDataService.createUserForTest('1teritorry11111@test.com') ;
        Territory__c parent = TestDataService.createTerritoryForTest('Japan');
        Territory__c child = TestDataService.createTerritoryForTest('Tokyo', parent.Id);
        List <Account> accs = TestDataService.createAccountsWithTerritoryForTest(2, 'Tokyo Account', child.Id);
        List <Contact> contacts = TestDataService.createContactsForTest(2, 'Tokyo Contact');
//Account dummyAccount = new Account(Name='DummyAccount');
// insert dummyAccount;
// contacts[0].Account=dummyAccount; 
// contacts[1].Account=dummyAccount;
        TestDataService.createReferenceForTest('TokyoRef0', accs[0], contacts[0]);
        TestDataService.createReferenceForTest('TokyoRef1', accs[1], contacts[1]);
        TestDataService.createTerrUserForTest('TokyoTerrUser', child.Id, oldUser.Id);
    }
    public class SharingSelector {

        public List<AccountShare> getAccountShares(Id UserId, List<Account> accounts) {
            return [
                    SELECT Id, AccountId, UserOrGroupId
                    FROM AccountShare
                    WHERE UserOrGroupId = :UserId
                    AND AccountId
                            IN :accounts
                    AND RowCause = 'Manual'
            ];
        }
        List<ContactShare> getContactShares(Id UserId, List<Contact> contacts) {
            return [
                    SELECT Id, ContactId, UserOrGroupId
                    FROM ContactShare
                    WHERE UserOrGroupId = :UserId
                    AND ContactId
                            IN :contacts
                    AND RowCause = 'Manual'
            ];
        }

    }
    public class ObjectSelector {
        TerrUser__c terrUser;
        User oldUser;
        List <Account> accs;
        List <Contact> contacts;
        public ObjectSelector() {
            this.terrUser = [SELECT Id,User__c,Territory__c,Name FROM TerrUser__c WHERE Name LIKE '%TokyoTerrUser%' LIMIT 1];
            this.oldUser = [SELECT Id FROM User WHERE Username = '1teritorry11111@test.com' LIMIT 1];
            this.accs = [SELECT Id FROM Account WHERE Name LIKE '%Tokyo Account%'];
            this.contacts = [SELECT Id FROM Contact WHERE Name LIKE '%Tokyo Contact%'];
        }

    }


    @IsTest
    public static void Test_Change_User_In_Territory_User1() {

        ObjectSelector objectSelector = new ObjectSelector();

        TerrUser__c terrUser = objectSelector.terrUser;
        User newUser = TestDataService.createUserForTest('2teritorry11111@test.com');

        Test.startTest();
        terrUser.User__c = newUser.Id;
        update terrUser;
        Test.stopTest();

        SharingSelector sharingSelector = new SharingSelector();

        List<AccountShare> sharesAccAfterUpdate = sharingSelector.getAccountShares(objectSelector.oldUser.Id, objectSelector.accs);
        List<ContactShare> sharesContAfterUpdate = sharingSelector.getContactShares(objectSelector.oldUser.Id, objectSelector.contacts);

        List<AccountShare> sharesAccForNewUser = sharingSelector.getAccountShares(newUser.Id, objectSelector.accs);
        List<ContactShare> sharesContForNewUser = sharingSelector.getContactShares(newUser.Id, objectSelector.contacts);

        System.assert(sharesAccAfterUpdate.isEmpty(), 'All Account shares was not deleted');
        System.assert(sharesContAfterUpdate.isEmpty(), 'All Contact shares was not deleted');
        System.assertEquals(2, sharesContForNewUser.size(), 'New User Don`t get all shares for Accounts');
        System.assertEquals(2, sharesAccForNewUser.size(), 'New User Don`t get all shares for Contacts');
    }
    @IsTest
    public static void Test_Territory_In_Territory_User2() {

        ObjectSelector objectSelector = new ObjectSelector();

        TerrUser__c terrUser = objectSelector.terrUser;
        Territory__c newTerritory = TestDataService.createTerritoryForTest('China');
        List<Account> newAccounts = TestDataService.createAccountsWithTerritoryForTest(2, 'China Account', newTerritory.Id);
        List <Contact> newContacts = TestDataService.createContactsForTest(2, 'Tokyo Contact');
        TestDataService.createReferenceForTest('ChinaRef0', newAccounts[0], newContacts[0]);
        TestDataService.createReferenceForTest('ChinaRef1', newAccounts[1], newContacts[1]);


        Test.startTest();
        terrUser.Territory__c = newTerritory.Id;
        update terrUser;
        Test.stopTest();

        SharingSelector sharingSelector = new SharingSelector();

        List<AccountShare> sharesAccAfterUpdate = sharingSelector.getAccountShares(objectSelector.oldUser.Id, objectSelector.accs);
        List<ContactShare> sharesContAfterUpdate = sharingSelector.getContactShares(objectSelector.oldUser.Id, objectSelector.contacts);

        List<AccountShare> sharesAccountsForNewTerritory = sharingSelector.getAccountShares(objectSelector.oldUser.Id, newAccounts);
        List<ContactShare> sharesContactsForNewTerritory = sharingSelector.getContactShares(objectSelector.oldUser.Id, newContacts);

        System.assert(sharesAccAfterUpdate.isEmpty(), 'All Account shares was not deleted');
        System.assert(sharesContAfterUpdate.isEmpty(), 'All Contact shares was not deleted');
        System.assertEquals(2, sharesAccountsForNewTerritory.size(), 'User Don`t get all shares for Accounts related with new territory');
        System.assertEquals(2, sharesContactsForNewTerritory.size(), 'User Don`t get all shares for Contacts related with new territory');
    }

    @IsTest
    public static void Test_Delete_Sub_Region_When_Sharirng_Is_Still_by_Parent3() {
        ObjectSelector objectSelector = new ObjectSelector();

        TerrUser__c terrUser = objectSelector.terrUser;
        Territory__c parentTerritory = [SELECT Id,Name FROM Territory__c WHERE Name = 'Japan'];
        //TestDataService.createTerrUserForTest('JapanTerrUser',objectSelector.terrUser.Territory__c,objectSelector.oldUser.Id);
        TestDataService.createTerrUserForTest('JapanTerrUser', parentTerritory.Id, objectSelector.oldUser.Id);
        System.debug(objectSelector.terrUser.Territory__c);
        SharingSelector sharingSelector = new SharingSelector();
        List<AccountShare> sharesAccBeforeDelete = sharingSelector.getAccountShares(objectSelector.oldUser.Id, objectSelector.accs);
        List<ContactShare> sharesContBeforeDelete = sharingSelector.getContactShares(objectSelector.oldUser.Id, objectSelector.contacts);

        System.assertEquals(2, sharesAccBeforeDelete.size(), 'User does not get all AccountShares');
        System.assertEquals(2, sharesContBeforeDelete.size(), 'User does not get all ContactShares');

        Test.startTest();
        delete terrUser;
        Test.stopTest();

        List<AccountShare> sharesAccAfterDelete = sharingSelector.getAccountShares(objectSelector.oldUser.Id, objectSelector.accs);
        List<ContactShare> sharesContAfterDelete = sharingSelector.getContactShares(objectSelector.oldUser.Id, objectSelector.contacts);

        System.assertEquals(2, sharesAccAfterDelete.size(), 'User lost AccountShares');
        System.assertEquals(2, sharesContAfterDelete.size(), 'User lost ContactShares');
    }

    @IsTest
    public static void Test_Reassign_Child_Territory_to_new_Hierarchy_wheer_Terruser_doesnt_exist4() {
        ObjectSelector objectSelector = new ObjectSelector();

        Territory__c newTerritory = TestDataService.createTerritoryForTest('China');
        Territory__c childTerritory = TestDataService.createTerritoryForTest('Shibuya(TokyoRegion)', objectSelector.terrUser.Territory__c);
        List <Account> accs = TestDataService.createAccountsWithTerritoryForTest(1, 'Shibuya Account', childTerritory.Id);
        List <Contact> contacts = TestDataService.createContactsForTest(1, 'Shibuya Contact');
        TestDataService.createReferenceForTest('ShibuyaRef1', accs[0], contacts[0]);
        SharingSelector sharingSelector = new SharingSelector();

        List<AccountShare> sharesAccBeforeUpdate = sharingSelector.getAccountShares(objectSelector.oldUser.Id, accs);
        List<ContactShare> sharesContBeforeUpdate = sharingSelector.getContactShares(objectSelector.oldUser.Id, contacts);
        System.assertEquals(1, sharesAccBeforeUpdate.size(), 'User does not get all shares for  new Accounts');
        System.assertEquals(1, sharesContBeforeUpdate.size(), 'User does not get all shares for  new Contacts');

        Test.startTest();
        childTerritory.Territory__c = newTerritory.Id;
        update childTerritory;
        Test.stopTest();

        List<AccountShare> sharesAccAfterUpdate = sharingSelector.getAccountShares(objectSelector.oldUser.Id, accs);
        List<ContactShare> sharesContAfterUpdate = sharingSelector.getContactShares(objectSelector.oldUser.Id, contacts);

        System.assert(sharesAccAfterUpdate.isEmpty(), 'All Account shares was not deleted');
        System.assert(sharesContAfterUpdate.isEmpty(), 'All Contact shares was not deleted');
    }

    @IsTest
    public static void TestCreateNewAccount5() {
        ObjectSelector objectSelector = new ObjectSelector();

        Test.startTest();
        List<Account> newAccounts = TestDataService.createAccountsWithTerritoryForTest(2, 'New Tokyo Account', objectSelector.terrUser.Territory__c);
        Test.stopTest();

        SharingSelector sharingSelector = new SharingSelector();
        List<AccountShare> sharesWithNewAcc = sharingSelector.getAccountShares(objectSelector.oldUser.Id, newAccounts);

        System.assertEquals(2, sharesWithNewAcc.size(), 'User don`t get all shares for  new Accounts');
    }

    @IsTest
    public static void Test_Delete_One_Reference_Object_With_the_Same_Contact_When_Second_IsShared_by_Another_Territory6() {

        ObjectSelector objectSelector = new ObjectSelector();

        List<Contact> contactForTest = new List<Contact>{
                objectSelector.contacts[0]
        };
        Territory__c secondTerritory = TestDataService.createTerritoryForTest('China');
        TerrUser__c newTerrUser = TestDataService.createTerrUserForTest('ChinaTerrUser', secondTerritory.Id, objectSelector.oldUser.Id);
        List<Account> chinaAccounts = TestDataService.createAccountsWithTerritoryForTest(1, 'China Account', secondTerritory.Id);
        Reference__c newReference = TestDataService.createReferenceForTest('China Acc TO TokyoContact0', chinaAccounts[0], contactForTest[0]);

        Test.startTest();
        delete newReference;
        Test.stopTest();

        SharingSelector sharingSelector = new SharingSelector();
        List<ContactShare> sharesAfterDelete = sharingSelector.getContactShares(objectSelector.oldUser.Id, contactForTest);

        System.assertEquals(sharesAfterDelete.size(), 1, 'User lost ContactShare');
    }

    @ IsTest
    public static void Test_Delete_first_Territory_When_Contacts_Is_Still_Shared_By_Second7() {

        ObjectSelector objectSelector = new ObjectSelector();
        SharingSelector sharingSelector = new SharingSelector();
        Territory__c oldTerritory = [SELECT Id FROM Territory__c WHERE Name LIKE '%Tokyo%'];
        Territory__c newTerritory = TestDataService.createTerritoryForTest('China');
        List <Account> accs = TestDataService.createAccountsWithTerritoryForTest(2, 'China Account', newTerritory.Id);
        TerrUser__c chinaTerrUser = TestDataService.createTerrUserForTest('ChinaTerrUser', newTerritory.Id, objectSelector.oldUser.Id);
//        Territory__c childTerritory = TestDataService.createTerritoryForTest('Shibuya(TokyoRegion)',objectSelector.terrUser.Territory__c);
//        List <Account> accs = TestDataService.createAccountsWithTerritoryForTest(1,'Shibuya Account',childTerritory.Id);
//        List <Contact> contacts = TestDataService.createContactsForTest(1,'Shibuya Contact');

        TestDataService.createReferenceForTest('ChinaAccountToTokyoContact', accs[0], objectSelector.contacts[0]);
        TestDataService.createReferenceForTest('ChinaAccountToTokyoContact', accs[1], objectSelector.contacts[1]);
        List<ContactShare> sharesContactBeforeUpdate = sharingSelector.getContactShares(objectSelector.oldUser.Id, objectSelector.contacts);
        Test.startTest();

        delete oldTerritory;


        List<ContactShare> sharesContAfterUpdate = sharingSelector.getContactShares(objectSelector.oldUser.Id, objectSelector.contacts);

        Test.stopTest();


        //System.assertEquals(sharesAccAfterUpdate.size(),1,'User lost AccountShare');
        //System.debug(sharesContAfterUpdate);
        // System.assertEquals(sharesContactBeforeUpdate[0].ContactId,sharesContAfterUpdate[0].ContactId);
        System.assertEquals(2, sharesContAfterUpdate.size(), 'User lost ContactShare');


    }

    @ IsTest
    public static void Test_Same_Territory_Name8() {

        Boolean isError = false;

        Test.startTest();

        try {
            TestDataService.createTerritoryForTest('Japan');
        } catch (Exception e) {
            isError = true;
        }

        Test.stopTest();

        System.assert(isError, 'Territory was created with same name on the same level hierarchy');

    }

    @IsTest
    public static void Test_Delete_Mid_Terr_With_Parent_Accounts_should_be_Reasigned_toParent_Advanced9() {

        ObjectSelector objectSelector = new ObjectSelector();

        Territory__c childTerritory = TestDataService.createTerritoryForTest('Shibuya(TokyoRegion)', objectSelector.terrUser.Territory__c);
        List <Account> accs = TestDataService.createAccountsWithTerritoryForTest(1, 'Shibuya Account', childTerritory.Id);
        List <Contact> contacts = TestDataService.createContactsForTest(1, 'Shibuya Contact');
        TestDataService.createReferenceForTest('ShibuyaRef1', accs[0], contacts[0]);
        Territory__c actualTerritory = [SELECT Id,Territory__c FROM Territory__c WHERE Name = 'Tokyo'];

        Id parentTerritory = actualTerritory.Territory__c;

        TerrUser__c terrUser = TestDataService.createTerrUserForTest('JapanTerrUser', parentTerritory, objectSelector.oldUser.Id);

        Test.startTest();
        delete actualTerritory;

        SharingSelector sharingSelector = new SharingSelector();

        List<AccountShare> sharesAccAfterUpdate = sharingSelector.getAccountShares(objectSelector.oldUser.Id, accs);
        List<ContactShare> sharesContAfterUpdate = sharingSelector.getContactShares(objectSelector.oldUser.Id, contacts);

        Test.stopTest();

        List<Account> tokyoAccsAfterRemoveTerr = [SELECT Id,Territory__c,Territory__r.Name FROM Account WHERE Name LIKE '%Tokyo Account%'];
        for (Account acc : tokyoAccsAfterRemoveTerr) {
            System.assertEquals(acc.Territory__c, parentTerritory, 'Account.Territory__c after delete his territory not equal parent Territory__c');
        }
        Territory__c childTerrsAfterRemoveTerr = [SELECT Id,Territory__c,Name,Territory__r.Name FROM Territory__c WHERE Name = 'Shibuya(TokyoRegion)' LIMIT 1];

        System.assertEquals(childTerrsAfterRemoveTerr.Territory__c, parentTerritory, 'child Territory__c after delete parent territory not equal higher level Territory__c');

        System.assertEquals(1,sharesAccAfterUpdate.size(), 'User lost AccountShare');
        System.assertEquals(1,sharesContAfterUpdate.size(), 'User lost ContactShare');

    }
    @IsTest
    public static void Test_Create_Contact_Advanced10() {
        Boolean contactWithoutAccountId = false;

        List<Contact> newContacts = new List<Contact>();
        newContacts.add(new Contact(LastName = 'TestContact1'));
        newContacts.add(new Contact(LastName = 'TestContact2'));

        Test.startTest();
        insert newContacts;
        Test.stopTest();

        List<Contact> contactsAfterInsert = [SELECT Id,Name,AccountId FROM Contact WHERE Name LIKE '%TestContact%'];
        for (Contact cont : contactsAfterInsert) {
            if (cont.AccountId == null) {
                contactWithoutAccountId = true;
            }
        }
        System.assertEquals(false, contactWithoutAccountId, 'Contact AccountId==null');

    }
    @IsTest
    public static void Test_Reasign_Accounts_To_New_Territory_without_Terruser11() {
        ObjectSelector objectSelector = new ObjectSelector();

        //TerrUser__c terrUser = objectSelector.terrUser;
        Territory__c newTerritory = TestDataService.createTerritoryForTest('China');
        //TestDataService.createTerrUserForTest('JapanTerrUser',objectSelector.terrUser.Territory__c,objectSelector.oldUser.Id);

        System.debug(objectSelector.terrUser.Territory__c);
        SharingSelector sharingSelector = new SharingSelector();
        List<AccountShare> sharesAccBeforeUpdate = sharingSelector.getAccountShares(objectSelector.oldUser.Id, objectSelector.accs);
        List<ContactShare> sharesContBeforeUpdate = sharingSelector.getContactShares(objectSelector.oldUser.Id, objectSelector.contacts);

        System.assertEquals(2, sharesAccBeforeUpdate.size(), 'User does not get all shares for  new Accounts');
        System.assertEquals(2, sharesContBeforeUpdate.size(), 'User does not get all shares for  new Contacts');

        Test.startTest();
        objectSelector.accs[0].Territory__c = newTerritory.Id;
        objectSelector.accs[1].Territory__c = newTerritory.Id;
        update objectSelector.accs;
        Test.stopTest();

        List<AccountShare> sharesAccAfterChangeTerritory = sharingSelector.getAccountShares(objectSelector.oldUser.Id, objectSelector.accs);
        List<ContactShare> sharesContAfterChangeTerritory = sharingSelector.getContactShares(objectSelector.oldUser.Id, objectSelector.contacts);

        System.assert(sharesAccAfterChangeTerritory.isEmpty(), 'User does not lost AccountShares');
        System.assert(sharesContAfterChangeTerritory.isEmpty(), 'User  does not lost ContactShares');
    }

    @IsTest
    public static void TestCreateTerrUser12() {
        User oldUser = TestDataService.createUserForTest('1teritorryZZZZZ@test.com') ;
        Territory__c parent = TestDataService.createTerritoryForTest('China');
        List <Account> accs = TestDataService.createAccountsWithTerritoryForTest(1, 'China Account', parent.Id);
        List <Contact> contacts = TestDataService.createContactsForTest(1, 'China Contact');
        TestDataService.createReferenceForTest('TokyoRef0', accs[0], contacts[0]);
        SharingSelector sharingSelector = new SharingSelector();
        List<AccountShare> sharesAccBeforeCreateTerrUser = sharingSelector.getAccountShares(oldUser.Id, accs);
        List<ContactShare> sharesContBeforeCreateTerrUser = sharingSelector.getContactShares(oldUser.Id, contacts);
        System.assert(sharesAccBeforeCreateTerrUser.isEmpty(), 'User has account sharings without terrUser');
        System.assert(sharesContBeforeCreateTerrUser.isEmpty(), 'User has contact sharings without terrUser');

        Test.startTest();
        TestDataService.createTerrUserForTest('ChinaTerrUser', parent.id, oldUser.Id);
        Test.stopTest();

        List<AccountShare> sharesAccAfterCreateTerrUser = sharingSelector.getAccountShares(oldUser.Id, accs);
        List<ContactShare> sharesContAfterCreateTerrUser = sharingSelector.getContactShares(oldUser.Id, contacts);
        System.assertEquals(1, sharesAccAfterCreateTerrUser.size(), 'User did not get account sharings after create terrUser');
        System.assertEquals(1, sharesContAfterCreateTerrUser.size(), 'User did not get contact sharings after create terrUser');
    }

    @IsTest
    public static void TestDeleteTerrUser13() {
        ObjectSelector objectSelector = new ObjectSelector();
        SharingSelector sharingSelector = new SharingSelector();
        List<AccountShare> sharesAccBeforeCreateTerrUser = sharingSelector.getAccountShares(objectSelector.oldUser.Id, objectSelector.accs);
        List<ContactShare> sharesContBeforeCreateTerrUser = sharingSelector.getContactShares(objectSelector.oldUser.Id, objectSelector.contacts);
        System.assertEquals(2, sharesAccBeforeCreateTerrUser.size(), 'User did not get account sharings after create terrUser');
        System.assertEquals(2, sharesContBeforeCreateTerrUser.size(), 'User did not get contact sharings after create terrUser');

        Test.startTest();
        delete objectSelector.terrUser;
        Test.stopTest();

        List<AccountShare> sharesAccAfterCreateTerrUser = sharingSelector.getAccountShares(objectSelector.oldUser.Id, objectSelector.accs);
        List<ContactShare> sharesContAfterCreateTerrUser = sharingSelector.getContactShares(objectSelector.oldUser.Id, objectSelector.contacts);
        System.assert(sharesAccAfterCreateTerrUser.isEmpty(), 'User did not get account sharings after create terrUser');
        System.assert(sharesContAfterCreateTerrUser.isEmpty(), 'User did not get contact sharings after create terrUser');
    }

}