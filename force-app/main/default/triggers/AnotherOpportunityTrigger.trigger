/*
AnotherOpportunityTrigger Overview

This trigger was initially created for handling various events on the Opportunity object. It was developed by a prior developer and has since been noted to cause some issues in our org.

IMPORTANT:
- This trigger does not adhere to Salesforce best practices.
- It is essential to review, understand, and refactor this trigger to ensure maintainability, performance, and prevent any inadvertent issues.

ISSUES:
Avoid nested for loop - 1 instance
Avoid DML inside for loop - 1 instance
Bulkify Your Code - 1 instance
Avoid SOQL Query inside for loop - 2 instances
Stop recursion - 1 instance

RESOURCES: 
https://www.salesforceben.com/12-salesforce-apex-best-practices/
https://developer.salesforce.com/blogs/developer-relations/2015/01/apex-best-practices-15-apex-commandments
*/
trigger AnotherOpportunityTrigger on Opportunity (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    if (Trigger.isBefore){
        if (Trigger.isInsert){
            // Set default Type for new Opportunities
            Opportunity opp = Trigger.new[0];
            if (opp.Type == null){
                opp.Type = 'New Customer';
            }        
        } else if (Trigger.isDelete){
            // Prevent deletion of closed Opportunities
            for (Opportunity oldOpp : Trigger.old){
                if (oldOpp.IsClosed){
                    oldOpp.addError('Cannot delete closed opportunity');
                }
            }
        }
    }

    if (Trigger.isAfter){
        if (Trigger.isInsert){
            // Create a new Task for newly inserted Opportunities
            List <Task> taskList  = new List <Task>();
            for (Opportunity opp : Trigger.new){
                Task tsk = new Task();
                tsk.Subject = 'Call Primary Contact';
                tsk.WhatId = opp.Id;
                tsk.WhoId = opp.Primary_Contact__c;
                tsk.OwnerId = opp.OwnerId;
                tsk.ActivityDate = Date.today().addDays(3);
                taskList.add(tsk);
            }
            if(!taskList.isEmpty()){
                insert taskList;
            }
        } else if (Trigger.isUpdate){
            // Check the static variable to prevent recursion
            if (!OpportunityHelper.isTriggerExecuted) {
                OpportunityHelper.isTriggerExecuted = true; // Set the flag
                // Append Stage changes in Opportunity Description
                for (Opportunity opp : Trigger.new){
                    //for (Opportunity oldOpp : Trigger.old){
                    //Assign the old record to oldOpp
                    Opportunity oldOpp = Trigger.oldMap.get(opp.Id);
                    if(opp.Description == null){
                        //Ensure description is not null to avoid execution error
                        opp.Description = '';
                    } 
                    if (opp.StageName != null && opp.StageName != oldOpp.StageName){
                        opp.Description += '\n Stage Change:' + opp.StageName + ':' + DateTime.now().format();
                    } 
                }  
            
                update Trigger.new;
            }
            
        }
        // Send email notifications when an Opportunity is deleted 
        else if (Trigger.isDelete){
            notifyOwnersOpportunityDeleted(Trigger.old);
        } 
        // Assign the primary contact to undeleted Opportunities
        else if (Trigger.isUndelete){
            assignPrimaryContact(Trigger.newMap);
        }
    }

    /*
    notifyOwnersOpportunityDeleted:
    - Sends an email notification to the owner of the Opportunity when it gets deleted.
    - Uses Salesforce's Messaging.SingleEmailMessage to send the email.
    */
    private static void notifyOwnersOpportunityDeleted(List<Opportunity> opps) {
        // Collect all owner IDs
        Set<Id> ownerIds = new Set<Id>();
        for (Opportunity opp : opps) {
            if (opp.OwnerId != null) {
                ownerIds.add(opp.OwnerId);
            }
        }
    
        // Query Users with OwnerId
        Map<Id, User> ownerIdToUserMap = new Map<Id, User>(
            [SELECT Id, Email FROM User WHERE Id IN :ownerIds]
        );
    
        // Create email messages
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        for (Opportunity opp : opps) {
            User owner = ownerIdToUserMap.get(opp.OwnerId);
            if (owner != null) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new String[] { owner.Email });
                mail.setSubject('Opportunity Deleted : ' + opp.Name);
                mail.setPlainTextBody('Your Opportunity: ' + opp.Name + ' has been deleted.');
                mails.add(mail);
            }
        }
    
        try {
            Messaging.sendEmail(mails);
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }
    

    /*
    assignPrimaryContact:
    - Assigns a primary contact with the title of 'VP Sales' to undeleted Opportunities.
    - Only updates the Opportunities that don't already have a primary contact.
    */
    private static void assignPrimaryContact(Map<Id, Opportunity> oppNewMap) {
        // Collect all AccountIds from the opportunities
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : oppNewMap.values()) {
            if (opp.AccountId != null) {
                accountIds.add(opp.AccountId);
            }
        }
    
        // Query all relevant contacts upfront
        Map<Id, Contact> accountToPrimaryContactMap = new Map<Id, Contact>();
        for (Contact contact : [
            SELECT Id, AccountId 
            FROM Contact 
            WHERE Title = 'VP Sales' AND AccountId IN :accountIds
        ]) {
            accountToPrimaryContactMap.put(contact.AccountId, contact);
        }
    
        // Prepare the opportunities to update
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        for (Opportunity opp : oppNewMap.values()) {
            if (opp.Primary_Contact__c == null && accountToPrimaryContactMap.containsKey(opp.AccountId)) {
                Opportunity oppToUpdate = new Opportunity(Id = opp.Id);
                oppToUpdate.Primary_Contact__c = accountToPrimaryContactMap.get(opp.AccountId).Id;
                oppMap.put(opp.Id, oppToUpdate);
            }
        }
    
        // Perform the update if there are any changes
        if (!oppMap.isEmpty()) {
            update oppMap.values();
        }
    }
}