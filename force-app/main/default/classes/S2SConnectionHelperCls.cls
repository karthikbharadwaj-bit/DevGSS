/**************************************************************************************************
* Project Name..........: Telus-RC S2S                                                            *
* File..................: S2SConnectionHelperCls.class                                    		  *
* Version...............: 1.0                                                                     *
* Created by............: Simplion Technologies                                                   *
* Created Date..........: September 1, 2014                                                       *
* Last Modified by......: Simplion Technologies                                                   *
* Last Modified Date....: September 3, 2014                                                       *
* Description...........: General helper class for getting S2S connection informations			  *
**************************************************************************************************/
public without sharing class S2SConnectionHelperCls {

	/****************************************************************************************
	 * @Description - Method to get Network Connection Id     								*
	 * @params String																		*
	 * @return Id      			                                                        	*
	 ***************************************************************************************/
    public static Set<Id> getConnectionId(String connectionName) {
        Set<Id> connectionIdSet = new Set<Id>();
        try {
            Map<Id, PartnerNetworkConnection> queryResult = new Map<Id, PartnerNetworkConnection>([
                SELECT Id
                FROM PartnerNetworkConnection
                WHERE ConnectionStatus = 'Accepted' AND ConnectionName = :connectionName
            ]);

            connectionIdSet = queryResult.keySet();
        }
        catch (Exception ex) {
            throw ex;
        }
        return connectionIdSet;
    }
}