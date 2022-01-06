@IsTest
public with sharing class DefineTriggersTest {
    @IsTest
    private static void checkExistenceOfTriggers() {
        List<String>objectNames = new List<String>{
                'Account','Territory__c','Reference__c','TerrUser__c'
        };
        List<AggregateResult>aggregateResults = [
                SELECT TableEnumOrId, Count(Id)
                FROM ApexTrigger
                WHERE TableEnumOrId IN:objectNames
                GROUP BY TableEnumOrId
        ];
        System.assertEquals(objectNames.size(),aggregateResults.size(),'There are  no triggers for all object in list');
    }
}