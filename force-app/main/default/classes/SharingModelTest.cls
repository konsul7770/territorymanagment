@IsTest
public with sharing class SharingModelTest {
    private static List<String> devNamesToCheck = new List<String>{
            'Account','Contact','Territory__c','TerrUser__c'
    };
    @IsTest
    public static void test1() {
        List<EntityDefinition> eds = [
                SELECT DeveloperName,
                        ExternalSharingModel,
                        InternalSharingModel
                FROM EntityDefinition
                WHERE DeveloperName IN : devNamesToCheck
        ];

        for(EntityDefinition e:eds){
            System.assert(e.InternalSharingModel=='Private','private model is not set on'+ e.DeveloperName);
        }
    }
}