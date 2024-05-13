public class OpportunityTriggerHandler extends TriggerHandler {
    
    private List<Opportunity> newOppList;
    private List<Opportunity> oldOppList;
    private Map<Id,Opportunity> newOppMap;
    private Map<Id,Opportunity> oldOppMap;

    public OpportunityTriggerHandler() {
        
        this.newOppList = (List<Opportunity>)Trigger.new;
        this.oldOppList = (List<Opportunity>)Trigger.old;
        this.newOppMap = (Map<Id,Opportunity>)Trigger.newMap;
        this.oldOppMap = (Map<Id,Opportunity>)Trigger.oldMap;
        //this.setMaxLoopCount(1);

    }
    
    public override void beforeInsert() {

        // Set default Type for new Opportunities            
        for (Opportunity Opp : this.newOppList) {
            if (opp.Type == null){
                opp.Type = 'New Customer';
            }
        }        
    }

    public override void beforeUpdate() {

        // *** Validate that the amount is greater than 5000.
        
        for(Opportunity opp : this.newOppList) {
            if(opp.Amount <= 5000){
                opp.addError('Opportunity amount must be greater than 5000');
            }
        }

        // *** Set the primary contact on the opportunity to the contact with the title of 'CEO'.
    
        // Get contacts related to the opportunity account
        Set<Id> accountIds = new Set<Id>();
        for(Opportunity opp : this.newOppList) {
            accountIds.add(opp.AccountId);
        }
        
        Map<Id, Contact> contacts = new Map<Id, Contact>([
            SELECT Id, FirstName, AccountId FROM Contact 
            WHERE AccountId IN :accountIds AND Title = 'CEO' ORDER BY FirstName ASC]);
        Map<Id, Contact> accountIdToContact = new Map<Id, Contact>();

        for (Contact cont : contacts.values()) {
            if (!accountIdToContact.containsKey(cont.AccountId)) {
                accountIdToContact.put(cont.AccountId, cont);
            }
        }

        for(Opportunity opp : this.newOppList){
            if(opp.Primary_Contact__c == null){
                if (accountIdToContact.containsKey(opp.AccountId)){
                    opp.Primary_Contact__c = accountIdToContact.get(opp.AccountId).Id;
                }
            }
        }
    }

    public override void beforeDelete() {

        // *** Prevent the deletion of a closed won opportunity if the account industry is 'Banking'.
        //Get Account related to the opportunities 
        Map<Id, Account> accounts = new Map<Id, Account>([SELECT Id, Industry FROM Account WHERE Id IN (SELECT AccountId FROM Opportunity WHERE Id IN :this.oldOppList)]);
        for(Opportunity opp : this.oldOppList){
            if(opp.StageName == 'Closed Won'){
                if(accounts.get(opp.AccountId).Industry == 'Banking'){
                    opp.addError('Cannot delete closed opportunity for a banking account that is won');
                }
            }
        }
    }

    public override void afterInsert() {

        // Create a new Task for newly inserted Opportunities
        List<Task> tasks = new List<Task>();
        for (Opportunity opp : newOppList){
            Task tsk = new Task();           
            tsk.Subject = 'Call Primary Contact';
            tsk.WhatId = opp.Id;
            tsk.WhoId = opp.Primary_Contact__c;
            tsk.OwnerId = opp.OwnerId;
            tsk.ActivityDate = Date.today().addDays(3);
            tasks.add(tsk);                
        }
        insert tasks;
    }

    public override void afterUpdate() {

        // Append Stage changes in Opportunity Description
        Map<Id, Opportunity> oldOppMaps = new Map<Id, Opportunity>(this.oldOppList);

        List<Opportunity> oppsToUpdate = new List<Opportunity>();

        for (Opportunity opp : this.newOppList){
            Opportunity oldOpp = oldOppMaps.get(opp.Id);
            
            if (opp.StageName != null && opp.StageName != oldOpp.StageName){
                Opportunity oppToUpdate = new Opportunity(Id = opp.Id);
                oppToUpdate.Description = opp.Description + '\n Stage Change:' + opp.StageName + ':' + DateTime.now().format();
                oppsToUpdate.add(oppToUpdate);
            }
        }
        update oppsToUpdate;
    }

    public override void afterDelete() {
        /*
        notifyOwnersOpportunityDeleted:
        - Sends an email notification to the owner of the Opportunity when it gets deleted.
        - Uses Salesforce's Messaging.SingleEmailMessage to send the email.
        */

        OpportunityTriggerHelper.notifyOwnersOpportunityDeleted(this.oldOppList);
    
    }

    public override void afterUndelete() {
        System.Debug('Opportunity Trigger After Undelete');

        // assignPrimaryContact:
        // - Assigns a primary contact with the title of 'VP Sales' to undeleted Opportunities.
        // - Only updates the Opportunities that don't already have a primary contact.
        
        OpportunityTriggerHelper.assignPrimaryContact(this.newOppMap); 

    }
}