@IsTest
public with sharing class TerritoryUserProfileExistenceTest {

    private static  List<String> profilesToSearch = new List<String>{'TerritoryUser'};

    @IsTest
    public  static void checkProfileExistence () {
        List<Profile> actualProfiles = [SELECT Id,Name FROM Profile WHERE Name IN : profilesToSearch];
        System.assertEquals(profilesToSearch.size(),actualProfiles.size());
    }
}