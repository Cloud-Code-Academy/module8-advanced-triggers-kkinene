
public with sharing class OpportunityHelper {
    public static Boolean isTriggerExecuted = false;
    
    public void handleBeforeUpdate(List<Opportunity> newOpportunities, Map<Id, Opportunity> oldMap) {
        enforceAmountThreshold(newOpportunities);
        setPrimaryContact(newOpportunities);
    }

    public void handleBeforeDelete(List<Opportunity> oldOpportunities) {
        preventBankingAccountDeletion(oldOpportunities);
    }

    private void enforceAmountThreshold(List<Opportunity> opportunities) {
        for (Opportunity opp : opportunities) {
            if (opp.Amount < 5000) {
                opp.addError('Opportunity amount must be greater than 5000');
            }
        }
    }

    private void preventBankingAccountDeletion(List<Opportunity> opportunities) {
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : opportunities) {
            if (opp.StageName == 'Closed Won') {
                accountIds.add(opp.AccountId);
            }
        }

        if (!accountIds.isEmpty()){
            Map<Id, Account> accounts = new Map<Id, Account>([SELECT Id, Industry FROM Account WHERE Id IN :accountIds]);
            for (Opportunity opp : opportunities) {
                if (opp.StageName == 'Closed Won') {
                    if (accounts.containsKey(opp.AccountId) && accounts.get(opp.AccountId).Industry == 'Banking') {
                        opp.addError('Cannot delete a closed won opportunity for a banking account');
                    }
                }
            }
        }
    }

    private void setPrimaryContact(List<Opportunity> opportunities) {
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : opportunities) {
            accountIds.add(opp.AccountId);
        }

        if (!accountIds.isEmpty()){
            Map<Id, Contact> accountIdToContact = new Map<Id, Contact>();
            for(Contact c : [SELECT Id, AccountId FROM Contact WHERE AccountId IN :accountIds AND Title = 'CEO' ORDER BY FirstName ASC]){
                if(!accountIdToContact.containsKey(c.AccountId)){
                    accountIdToContact.put(c.AccountId,c);
                }
            }
            for (Opportunity opp : opportunities) {
                if (opp.Primary_Contact__c == null && accountIdToContact.containsKey(opp.AccountId)) {
                    opp.Primary_Contact__c = accountIdToContact.get(opp.AccountId).Id;
                }
            }
        }
    }
}