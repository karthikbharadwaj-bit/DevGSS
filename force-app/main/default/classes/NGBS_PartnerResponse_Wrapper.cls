public class NGBS_PartnerResponse_Wrapper {

	public Integer id;
	public String companyName;
	public String firstName;
	public String lastName;
	public String hierarchyType;
	public String externalPartnerAccountId;
	public Integer businessIdentityId;
	public String partnerType;
	public String status;
	public Integer parentId;
	public Integer csn;

	
	public static NGBS_PartnerResponse_Wrapper parse(String json) {
		return (NGBS_PartnerResponse_Wrapper) System.JSON.deserialize(json, NGBS_PartnerResponse_Wrapper.class);
	}
}