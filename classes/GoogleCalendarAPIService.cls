//Google Calendar API Service
public class GoogleCalendarAPIService {
    private static final GoogleAPISettings__c GOOGLE_API = GoogleAPISettings__c.getOrgDefaults();
    
    //Authorization
    public static Boolean getToken(String email,String code){
        Boolean isSuccess = false;
        try{
            
            String endPoint = 'https://www.googleapis.com/oauth2/v4/token';
            String client_id = GOOGLE_API.Client_Id__c;
            String client_secret = GOOGLE_API.Client_Secret__c;
            String redirect_uri = GOOGLE_API.Redirect_URL__c;
            
            String requestTokenBody = 'code='+code+'&client_id='+client_id+'&client_secret='+
                client_secret+'&redirect_uri='+redirect_uri+
                '&grant_type=authorization_code';
            
            Http http = new Http();
            httpRequest httpReq = new httpRequest();
            HttpResponse response = new HttpResponse();
            httpReq.setEndPoint(endPoint);
            httpReq.setBody(requestTokenBody);
            httpReq.setMethod('POST');
            httpReq.setTimeout(120000);
            httpReq.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            response = http.send(httpReq);
            system.debug(response.getBody()); 
            
            if(response.getStatusCode() == 200){
                CalenderAuthSettings__c obj = CalenderAuthSettings__c.getInstance(email) != null ? 
                    CalenderAuthSettings__c.getInstance(email) : new CalenderAuthSettings__c(Name = email);
                Map<String,String> result = new Map<String,String>((Map<String,String>)JSON.deserialize(response.getBody(),Map<String,String>.class));
                obj.Token__c = result.get('access_token');
                obj.Refresh_Token__c  = result.get('refresh_token');
                upsert obj;
                List<Contact> contacts = new List<Contact>([SELECT Id,Calendar_Shared__c
                                                            FROM Contact
                                                            Where Email =: email
                                                            AND RecordType.DeveloperName = 'Physician'
                                                            AND Calendar_Shared__c  = false]); 
                for(Contact objCon : contacts){
                    objCon.Calendar_Shared__c = true;                      
                }
                update contacts;
                isSuccess = true;
            }
        }
        catch(Exception ex){
            
            system.debug(ex.getMessage()+ex.getStackTraceString());
        }
        
        return isSuccess;
    }
    
    //Fetch refresh token
    public static CalenderAuthSettings__c getRefreshToken(CalenderAuthSettings__c obj){
        
        try{
            
            String endPoint = 'https://www.googleapis.com/oauth2/v4/token';
            String client_id = GOOGLE_API.Client_Id__c;
            String client_secret = GOOGLE_API.Client_Secret__c;
            String redirect_uri = GOOGLE_API.Redirect_URL__c;
            
            String requestTokenBody = 'client_id='+client_id+'&client_secret='+
                client_secret+'&refresh_token='+ obj.Refresh_Token__c +
                '&grant_type=refresh_token';
            
            Http http = new Http();
            httpRequest httpReq = new httpRequest();
            HttpResponse response = new HttpResponse();
            httpReq.setEndPoint(endPoint);
            httpReq.setBody(requestTokenBody);
            httpReq.setMethod('POST');
            httpReq.setTimeout(120000);
            httpReq.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            response = http.send(httpReq);
            system.debug(response.getBody());
            
            if(response.getStatusCode() == 200){
                
                Map<String,String> result = new Map<String,String>((Map<String,String>)JSON.deserialize(response.getBody(),Map<String,String>.class));
                obj.Token__c = result.get('access_token');
            }
        }
        catch(Exception ex){
            
            system.debug(ex.getMessage()+ex.getStackTraceString());
        }
        
        return obj;        
    }
    
    //Fetch events
    public static List<Map<String,Object>> getEvents(CalenderAuthSettings__c obj,String contextDate,String nextDate){
        
        List<Map<String,Object>> events = new List<Map<String,Object>>();
        try{
            Http http = new Http();
            httpRequest httpReq = new httpRequest();
            HttpResponse response = new HttpResponse();
            httpReq.setEndPoint('https://www.googleapis.com/calendar/v3/calendars/primary/events'+
                                '?timeMin='+contextDate+'T00:00:00Z'+
                                '&timeMax='+nextDate+'T00:00:00Z');
            httpReq.setMethod('GET');
            httpReq.setHeader('Content-Type', 'application/json');
            httpReq.setHeader('Authorization', 'Bearer '+ obj.Token__c);
            httpReq.setTimeout(120000);
            response = http.send(httpReq);
            system.debug(response.getBody());
            
            if(response.getStatusCode() == 200){
                Map<String,Object> results = new Map<String,Object>((Map<String, Object>) JSON.deserializeUntyped(response.getBody()));
                
                for(Object item : (List<Object>) results.get('items')){
                    Map<String,Object> event = ( Map<String,Object>) item;
                    String startT = '';
                    String endT = '';
                    if(event.containsKey('start')){
                        Map<String,Object> startDate = ( Map<String,Object>) event.get('start');
                        startT = String.valueOf(startDate.get('dateTime'));
                    }
                    if(event.containsKey('end')){
                        Map<String,Object> endDate = ( Map<String,Object>) event.get('end');
                        endT = String.valueOf(endDate.get('dateTime'));
                    }
                    if(String.isNotBlank(startT) || String.isNotBlank(endT)){
                        events.add(new Map<String,Object>{'start' => startT,
                            'end' => endT,
                            'overlap' => false
                            });
                    }
                }
            }
            else{
                obj = getRefreshToken(obj);
                events = getEvents(obj,contextDate,nextDate);
                upsert obj;
            }
        }
        catch(Exception ex){
            system.debug(ex.getMessage()+ex.getStackTraceString());
        }
        return events;
    }
    
    //Create event
    public static Boolean createEvent(CalenderAuthSettings__c obj,String patientId,String physicianId,String startTime,String endTime){
        
        Boolean isSuccess = false;
        try{
            Http http = new Http();
            httpRequest httpReq = new httpRequest();
            HttpResponse response = new HttpResponse();
            httpReq.setEndPoint('https://www.googleapis.com/calendar/v3/calendars/primary/events?sendNotifications=true&sendUpdates=all');
            httpReq.setMethod('POST');
            httpReq.setTimeout(120000);
            httpReq.setHeader('Content-Type', 'application/json');
            httpReq.setHeader('Authorization', 'Bearer '+ obj.Token__c);
            Contact objPatient = [SELECT Id,Email FROM Contact WHERE Id =: patientId WITH SECURITY_ENFORCED][0];
            
            String body = '{"summary": "Appointment scheduled at Medical Clinic",'+
                '"location": "Medical Clinic",'+
                '"attendees":[{"email": "'+objPatient.Email+'"}],'+
                '"start":{"dateTime": "'+startTime+'","timeZone": "Asia/Kolkata"},'+
                '"end":{"dateTime": "'+endTime+'","timeZone": "Asia/Kolkata"}}';
            httpReq.setBody(body);
            response = http.send(httpReq);
            system.debug(response.getBody());
            
            if(response.getStatusCode() != 200){
                
                obj = getRefreshToken(obj);
                createEvent(obj,patientId,physicianId,startTime,endTime);
                upsert obj;
                isSuccess = true;
            }
            else{
                Contact objPhy = [SELECT Id,Specialization__c  FROM Contact WHERE Id =: physicianId WITH SECURITY_ENFORCED][0];
                Appointment__c  objApp =  new Appointment__c (Physician__c  = objPhy.Id,
                                                              Patient__c   = objPatient.Id,
                                                              Specialization__c  = objPhy.Specialization__c,
                                                              Start_Time__c  = DateTime.ValueofGmt(startTime.replace('T', ' ')),
                                                              End_Time__c  = DateTime.ValueofGmt(endTime.replace('T', ' ')));
                insert objApp;
            }
        }
        catch(Exception ex){
            system.debug(ex.getMessage()+ex.getStackTraceString());
        }
        return isSuccess;
    }
}