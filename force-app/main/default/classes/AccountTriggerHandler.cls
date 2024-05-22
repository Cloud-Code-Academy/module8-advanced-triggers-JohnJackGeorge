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

        AccountHelper.setTypeProspect(this.newAcctList);
        AccountHelper.addressCopy(this.newAcctList);
        AccountHelper.setRating(this.newAcctList);

    }

    public override void afterInsert() {

        // Create a contact for each account inserted
        AccountHelper.defaultContact(this.newAcctList);

    }

    public override void afterUpdate() {
    }

    public override void afterDelete() {
    }

    public override void afterUndelete() {
    }
    
}