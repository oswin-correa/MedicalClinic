@isTest
private class MedicalClinicTests {
    
    @isTest static void test_CalenderAuthController() {
        new CalenderAuthController().register();
    }
    
    @isTest static void test_AppointmentBookingController() {
        insert new CalenderAuthSettings__c(Name = 'oswinchris@gmail.com',Token__c='Sample',Refresh_Token__c='Sample');
        AppointmentBookingController.getPhysicians();
        AppointmentBookingController.getEvents('oswinchris@gmail.com','','');
        AppointmentBookingController.createEvent('oswinchris@gmail.com','','','','');
        GoogleCalendarAPIService.getRefreshToken(new CalenderAuthSettings__c(Refresh_Token__c = 'Sample'));
    } 
}