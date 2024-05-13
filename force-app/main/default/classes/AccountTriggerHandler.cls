public class AccountTriggerHandler extends TriggerHandler {

    private List<Account> newAcctList;
    private List<Account> oldAcctList;
    private Map<Id,Account> newAcctMap;
    private Map<Id,Account> oldAcctMap;

    public AccountTriggerHandler() {
        
        this.newAcctList = (List<Account>)Trigger.new;
        this.oldAcctList = (List<Account>)Trigger.old;
        this.newAcctMap = (Map<Id,Account>)Trigger.newMap;
        this.oldAcctMap = (Map<Id,Account>)Trigger.oldMap;
        //this.setMaxLoopCount(1);

    }
    public override void beforeInsert() {

        for(Account acc : this.newAcctList) {

            // Set the account type to prospect
            if (acc.Type == null) {
                acc.Type = 'Prospect';
            }
        
            // Copy the shipping address to the billing address.
            if (acc.ShippingStreet != null) {
                acc.BillingStreet = acc.ShippingStreet;
            }
            if (acc.ShippingCity != null) {
                acc.BillingCity = acc.ShippingCity;
            }
            if (acc.ShippingState != null) {
                acc.BillingState = acc.ShippingState;
            }
            if (acc.ShippingPostalCode != null) {
                acc.BillingPostalCode = acc.ShippingPostalCode;
            }
            if (acc.ShippingCountry != null) {
                acc.BillingCountry = acc.ShippingCountry;
            }

            // Set the account rating to 'Hot' if the Phone, Website, and Fax is not empty.
            if (acc.Phone != null && acc.Website != null && acc.Fax != null) {
                acc.Rating = 'Hot';
            }
        }
    }

    public override void beforeUpdate() {
        for(Account o : (List<Account>) Trigger.new) {
          // do something
        }
    }
    public override void beforeDelete() {
    }

    public override void afterInsert() {

        // Create a contact for each account inserted
        List<Contact> contactsToInsert = new List<Contact>();

        for(Account acc : this.newAcctList) {
            Contact con = new Contact();
            con.AccountId = acc.Id;
            con.LastName = 'DefaultContact';
            con.Email = 'default@email.com';
            contactsToInsert.add(con);
        }
        if(!contactsToInsert.isEmpty()) {
            insert contactsToInsert;
        }
    }

    public override void afterUpdate() {
    }

    public override void afterDelete() {
    }

    public override void afterUndelete() {
    }
    
}