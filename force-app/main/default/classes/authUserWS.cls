global class authUserWS{


//Define an object in apex that is exposed in apex web service
   global class authUserInputParam{
        /*InPut*/
        webservice String In_RCUserID;
        webservice String In_RCPrimaryNumber;
        webservice String In_ContactMail;

        /*OutPut*/
        webservice Boolean Out_Status;
        webservice String Out_UserID;
        webservice String Out_Password;
        /*New Addedition */
        webservice String Out_Brand;
        webservice String Out_Service;
        webservice String Out_Tier;
        webservice String Out_Token;
        webservice String Out_ServiceVersion;

   }

   webservice static authUserInputParam authUser(authUserInputParam vauthUserInputParam) {
        System.debug(''+ (vauthUserInputParam == null ? ' NULL INPUT ' : ' #### LOGIN CONTACT EMAIL ' + vauthUserInputParam.In_ContactMail + ' \n### ENTERPRISE ACCOUNT ID = ' + vauthUserInputParam.In_RCUserID));
        /*Logic to get USRID*/
        Integer resultUserNameLen = 0;
        String proc_EmailWORCUSERID = vauthUserInputParam.In_ContactMail;
        String proc_EmailWithRCUSERID = vauthUserInputParam.In_RCUserID + vauthUserInputParam.In_ContactMail;

        resultUserNameLen = proc_EmailWithRCUSERID.length();
        proc_EmailWithRCUSERID = proc_EmailWithRCUSERID.replace('@','.');
        if(resultUserNameLen > 70)
        {
            proc_EmailWithRCUSERID = proc_EmailWithRCUSERID.substring(0, 70);
        }
        proc_EmailWithRCUSERID = proc_EmailWithRCUSERID+'@rc.com';
        /**/

        /*Logic to get CONTACT ID*/
//       List<User> objUser = new List<User>();
        //WAS
//        List<Contact> objContact = [
//                            SELECT Id
//                            FROM Contact
//                            WHERE Account.RC_User_ID__c =: vauthUserInputParam.In_RCUserID
//                                AND Email =: vauthUserInputParam.In_ContactMail];
//
//        if(objContact.size() > 0)
//        {
//            objUser = [
//                    SELECT Id, Username, ProfileId, IsActive
//                    FROM User
//                    WHERE Contactid =: objContact[0].Id
//                        AND ProfileId IN :SyncAccountWS.PROFILE_IDS_OF_PORTAL_USERS
//                    LIMIT 1
//            ];

       List<User> objUser = [
           SELECT Id, UserName, ProfileId, IsActive
           FROM User
           WHERE User.Contact.Account.RC_User_ID__c =: vauthUserInputParam.In_RCUserID
           AND User.Contact.Email =: vauthUserInputParam.In_ContactMail
           AND ProfileId IN :SyncAccountWS.PROFILE_IDS_OF_PORTAL_USERS
           LIMIT 1
       ];

       if(objUser.size() > 0)
       {
            if(objUser[0]!=null && objUser[0].IsActive!=true){
                objUser[0].IsActive=true;
                update objUser[0];
            }

           for(User u: objUser) {
                    String strRandomPassword = getRandomPassword();//'verity11'; //'RC'+String.valueOf(Math.random());
                    system.setPassword(u.Id, strRandomPassword);
                    vauthUserInputParam.Out_UserID = u.Id;
                    vauthUserInputParam.Out_Password = strRandomPassword;
                    vauthUserInputParam.Out_Status = true;
                    vauthUserInputParam.Out_Token = '';
                    String strToken = 'un=' + u.username + '&pw=' +  strRandomPassword;
                    // Use generateAesKey to generate the private key
                    Blob cryptoKey = Blob.valueOf('v7Y2g2webAqutAcr4DEC3uTAnaspEgA8');
                    Blob initVector = Blob.valueof('da4atrABufastacr');
                    // Generate the data to be encrypted.
                    Blob data = Blob.valueOf(strToken);
                    // Encrypt the data and have Salesforce.com generate the initialization vector
                    Blob encryptedData = Crypto.encrypt('AES256', cryptoKey, initVector, data);
                    String strBase64Encoded =  EncodingUtil.base64Encode(encryptedData);
                    //vauthUserInputParam.Out_Token = EncodingUtil.urlEncode(strBase64Encoded, 'UTF-8') + '#' + strBase64Encoded;
                    vauthUserInputParam.Out_Token = strBase64Encoded;
                }
                List<Account> objAcctDet = [Select a.RC_User_ID__c, a.RC_Tier__c, a.RC_Service_name__c, a.RC_Brand__c, a.Id, a.Service_Version__c
                From Account a where RC_User_ID__c!=null and RC_User_ID__c =:vauthUserInputParam.In_RCUserID];
                if(objAcctDet.size() > 0){
                    for(Account acctDet: objAcctDet)
                    {
                        vauthUserInputParam.Out_Brand = acctDet.RC_Brand__c;
                        vauthUserInputParam.Out_Service = acctDet.RC_Service_name__c;
                        vauthUserInputParam.Out_Tier = acctDet.RC_Tier__c;
                        vauthUserInputParam.Out_ServiceVersion = '';
                    }
                }
       }else{
            vauthUserInputParam.Out_Status = false;
       }

       return vauthUserInputParam;
   }

   public static string getRandomPassword(){
     String initPw = 'Rc#';
     datetime myDateTime = datetime.now();
     Decimal decTime = myDateTime.getTime() /1000;
     Integer utctime = Math.round(decTime);
     initPw = initPw + String.valueOf(myDateTime.getTime());
     return initPw;
   }
}