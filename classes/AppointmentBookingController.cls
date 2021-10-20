public class AppointmentBookingController {
    
    @AuraEnabled
    public static Map<Id,Contact> getPhysicians(){
        return new Map<Id,Contact>([SELECT Id,Name,Email,Specialization__c,Specialization__r.Name,Specialization__r.Appointment_Price__c 
                                    FROM Contact
                                    WHERE RecordType.DeveloperName = 'Physician'
                                    AND Calendar_Shared__c  = true
                                    ORDER By Specialization__r.Name ASC]);
    }
    
    @AuraEnabled
    public static List<Map<String,Object>> getEvents(String email,String contextDate,String nextDate){
        return GoogleCalendarAPIService.getEvents(CalenderAuthSettings__c.getInstance(email),contextDate,nextDate);  
    }
    
    @AuraEnabled
    public static Boolean createEvent(String email,String patientId,String physicianId,String startTime,String endTime){
        
        return GoogleCalendarAPIService.createEvent(CalenderAuthSettings__c.getInstance(email),patientId,physicianId,startTime,endTime); 
    }
}