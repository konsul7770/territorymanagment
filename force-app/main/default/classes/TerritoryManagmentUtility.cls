public with sharing class TerritoryManagmentUtility {
    public static Boolean callFromDeleteTriggerContext = false;
    public static List<AccountShare> getAccountsShareObjects(Set<Id> userIds, Set<Id> accountIds) {
        return [
            SELECT
                Id,
                AccountId,
                AccountAccessLevel,
                UserOrGroupId,
                RowCause
            FROM AccountShare
            WHERE
                UserOrGroupId IN :userIds AND AccountId IN :accountIds AND RowCause =: Schema.AccountShare.RowCause.Manual
        ];
    }
    public static List<ContactShare> getContactsShareObjects(Set<Id> userIds,Set<Id> contactsIds) {
        return [
            SELECT
                Id,
                ContactId,
                ContactAccessLevel,
                UserOrGroupId,
                RowCause
            FROM ContactShare
            WHERE
                UserOrGroupId IN :userIds AND ContactId IN :contactsIds AND RowCause =: Schema.ContactShare.RowCause.Manual
        ];
    }
}
