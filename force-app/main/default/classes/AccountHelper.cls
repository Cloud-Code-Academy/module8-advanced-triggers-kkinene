/*
AccountHelper Overview

The `AccountHelper` class is designed to provide helper methods that assist in performing specific operations on Account records. 
This class is intended to modularize the logic used in the `AccountTrigger` to ensure separation of concerns, improve readability, and ease maintenance. 

This class is currently stubbed out. As part of this exercise, you are expected to:
1. Implement the method bodies to carry out the specified operations on Account records.
2. Refactor the `AccountTrigger` to utilize the methods provided in this `AccountHelper` class.

Methods:
- `setTypeProspect(SObject objects)`: 
    - Purpose: Update the 'Type' field of the given Account record to 'Prospect' if it's not already set.
    - Note: You'll likely need to adjust the method signature to accept the necessary parameters.

- `addressCopy()`: 
    - Purpose: Copy the shipping address of the Account to its billing address. 
    - Note: You'll likely need to adjust the method signature to accept the necessary parameters.

- `setRating`: 
    - Purpose: Evaluate certain conditions on the Account and assign a rating based on that evaluation. You'll need to define the method's signature and implement its logic.

- `defaultContact`: 
    - Purpose: Create a default contact related to the Account after the Account is inserted. You'll need to define the method's signature and implement its logic.

Remember:
Always ensure that your helper methods are bulk-safe to handle multiple records efficiently. 
*/
public with sharing class AccountHelper {
    
    //"static" allows us to call the method without creating an instance of the helper calls
    public static void setTypeProspect(List<Account> accRecords){
        //Make sure the list is not  empty
        if(accRecords == null || accRecords.isEmpty()){
            return;
        }

        for(Account tempAcc : accRecords){
            if(String.isBlank(tempAcc.Type)){
                tempAcc.Type = 'Prospect';
            }
        }
    }

    public static void addressCopy(List<Account> accRecords){
        for(Account tempAcc : accRecords){

            if (tempAcc.ShippingStreet != null) {
                tempAcc.BillingStreet = tempAcc.ShippingStreet;
            }

            if (tempAcc.ShippingCity != null) {
                tempAcc.BillingCity = tempAcc.ShippingCity;
            }

            if (tempAcc.ShippingState != null) {
                tempAcc.BillingState = tempAcc.ShippingState;
            }

            if (tempAcc.ShippingPostalCode != null) {
                tempAcc.BillingPostalCode = tempAcc.ShippingPostalCode;
            }

            if (tempAcc.ShippingCountry != null) {
                tempAcc.BillingCountry = tempAcc.ShippingCountry;
            }
        }             
    }

    public static void setRating(List<Account> accRecords){
        for(Account tempAcc: accRecords){  
            if (tempAcc.Phone != null && tempAcc.Website != null && tempAcc.Fax != null) {
                tempAcc.Rating = 'Hot';
            }            
        }
    }

    public static void defaultContact(List<Account> accRecords) {
        
        List<Contact> contacts = new List<Contact>();   
        for(Account tempAcc : accRecords){
            Contact con = new Contact();
            con.LastName = 'DefaultContact';
            con.Email = 'default@email.com';
            con.AccountId = tempAcc.Id;
            contacts.add(con);
        }
        
        if(!contacts.isEmpty()){
            insert contacts; 
        }
    }
}
