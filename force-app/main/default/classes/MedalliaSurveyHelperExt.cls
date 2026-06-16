/*
* Project Name..........: Medallia                                                               
* File..................: MedalliaSurveyHelperExt.class                                              
* Version...............: 1.0                                                                   
* Created by............: eugenebasianomutya                                                   
* Created Date..........: 09022016
* Description...........: This class is created to retrieve the User, User Manager of the CSM Account Team of Case, Opp and Acc
*/
public class MedalliaSurveyHelperExt{
        
    public map<Id, list<myUser>> MedalliaSurveyHelperProcess(set<Id> sAccId){
    
        String[] CSM = new String[]{'%CSM%'};
        Map<Id,myUser> sAcc_User = new Map<Id,myUser> ();
        Map<Id,Id> sUser_Manager = new Map<Id,Id> ();
        Map<Id,User> mManagerDetail = new Map<Id,User> ();

        // TO GET THE USER OF RECENT ACCOUNT TEAM OF ACCOUNT
        AggregateResult[]  AccountTeamMember  =  [SELECT Max(CreatedDate) cdate, Max(User.ManagerId) mId, Max(User.Email) uMail, Max(User.Name) uName, Max(UserId) uId, TeamMemberRole, AccountId
                                                  FROM AccountTeamMember 
                                                  WHERE TeamMemberRole LIKE :CSM 
                                                  AND AccountId IN: sAccId
                                                  GROUP BY AccountId,TeamMemberRole];

        for(AggregateResult atm: AccountTeamMember){
            system.debug('**ACCID** ' + atm.get('AccountId') + '**NAME** ' + atm.get('uname')  + '**ROLE** ' + atm.get('TeamMemberRole') + '**DATE** ' + atm.get('cdate')  );

            myUser u= new myUser();
            u.UserId = string.valueOf(atm.get('uId'));
            u.UserName = string.valueOf(atm.get('uName'));
            u.UserEmail = string.valueOf(atm.get('uMail'));

            sAcc_User.put(string.valueOf(atm.get('AccountId')), u );
            sUser_Manager.put(string.valueOf(atm.get('uId')), string.valueOf(atm.get('mId')));            
        }

        // TO GET THE MANAGER OF USER 
        if(sUser_Manager.size()> 0) {
            if(sUser_Manager.values().size()>0){
                mManagerDetail  = new Map<Id,User> ([select id, Name, Email FROM User WHERE ID IN: sUser_Manager.values()]);
            }
        }

        map<Id, list<myUser>> mAccountTeam = new map<Id, list<myUser>>();

        if(sAcc_User.size()>0){

            for(Id i: sAcc_User.keyset()){

                list<myUser> lMyUser = new list<myUser>();
                lMyUser.add(sAcc_User.get(i));

                ID uManId = sUser_Manager.get(sAcc_User.get(i).UserId);
                
                if(mManagerDetail.get(uManId) != NULL){         
                    myUser uTM = new myUser();
                    uTM.UserId = uManId;
                    uTM.UserName = mManagerDetail.get(uManId).Name;
                    uTM.UserEmail = mManagerDetail.get(uManId).Email;
                    lMyUser.add(uTM);                    
                }      
                
                mAccountTeam.put(i,lMyUser);         
            }
        }
        
        return mAccountTeam;
    }

    public class myUser{
        public string UserId{
            public get{ return UserId;}
            public set;
        }
        public string UserName{
            public get{ return UserName;}
            public set;
        }
        public string UserEmail{
            public get{ return UserEmail;}
            public set;
        }
    }

   
}