public class CalenderAuthController{
    public Boolean isSuccess {get;set;}
    public void register(){

        String email = ApexPages.currentPage().getParameters().get('state');
        String code = ApexPages.currentPage().getParameters().get('code');
        isSuccess = GoogleCalendarAPIService.getToken(email,code);
    }
}