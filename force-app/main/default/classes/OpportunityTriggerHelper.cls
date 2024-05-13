public with sharing class OpportunityTriggerHelper {

    /*
    notifyOwnersOpportunityDeleted:
    - Sends an email notification to the owner of the Opportunity when it gets deleted.
    - Uses Salesforce's Messaging.SingleEmailMessage to send the email.
    */
    public static void notifyOwnersOpportunityDeleted(List<Opportunity> oldOppList) {
    
        // Get all Owner Ids from the opportunities
        Set<Id> ownerIds = new Set<id>();
        for (Opportunity opp : oldOppList){
            ownerIds.add(opp.OwnerId);
        }

        // Query for the users outside the loop
        Map<Id, User> users = new Map<Id, User>([Select Id, Email FROM User WHERE Id IN :ownerIds]);

        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        for (Opportunity opp : oldOppList){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {users.get(opp.OwnerId).Email};
            mail.setToAddresses(toAddresses);
            mail.setSubject('Opportunity Deleted : ' + opp.Name);
            mail.setPlainTextBody('Your Opportunity: ' + opp.Name +' has been deleted.');
            mails.add(mail);
        }        
        
        try {
            Messaging.sendEmail(mails);
        } catch (Exception e){
            System.debug('Exception: ' + e.getMessage());
        }
    }

    /*
    assignPrimaryContact:
    - Assigns a primary contact with the title of 'VP Sales' to undeleted Opportunities.
    - Only updates the Opportunities that don't already have a primary contact.
    */
    public static void assignPrimaryContact(Map<Id,Opportunity> newOppMap) {
        // Get all Account Ids from the opportunities

        Set<Id> oppAccountIds = new Set<Id>();
        for (Opportunity opp : newOppMap.values()) {
            oppAccountIds.add(opp.AccountId);
        }
        ///List<Account> accounts = ([SELECT Id, Name. Website FROM Account WHERE Id IN :oppAccountIds]);
        List<Contact> contacts = [SELECT Id, AccountId, Name, Title FROM Contact WHERE Title = 'VP Sales' AND AccountId IN :oppAccountIds];

        // Query for contacts outside of the loop
        Map<Id, Contact> accountIdToContacts = new Map<Id, Contact>();

        for (Contact cont : contacts) {
            accountIdToContacts.put(cont.accountId, cont);
        }
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        for (Opportunity opp : newOppMap.values()){
            Id opportunityAccountId = opp.accountId;
            
            if (accountIdToContacts.containsKey(opportunityAccountId) && opp.Primary_Contact__c == null) {
                Contact primaryContact = accountIdToContacts.get(opportunityAccountId);

                Opportunity newOpp = new Opportunity(Id = opp.Id);
                newOpp.Primary_Contact__c = primaryContact.Id;

                oppsToUpdate.add(newOpp);
            }
        }

        update oppsToUpdate;
    }
}