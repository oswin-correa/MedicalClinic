({
    doInit : function(component) {
        
        var action = component.get("c.getPhysicians");
        action.setCallback(this, function(response) {
            
            if (response.getState() === "SUCCESS") {
                component.set('v.physicians',response.getReturnValue());
                this.handlePhysicians(component);
            }else{
                console.log(response.getError())
            }
        });
        $A.enqueueAction(action);
    },
    handleFetchEvents : function(component) {
        
        let calendar = component.find('calendar');
        let phy = component.find("Physician__c").get('v.value');
        let patient = component.find("Patient__c").get('v.value');
        let date = String(component.find("Date__c").get('v.value'));
        
        if($A.util.isEmpty(date) || $A.util.isEmpty(phy) || $A.util.isEmpty(patient)){
            
            component.set('v.selectedPhysician',undefined);
            $A.util.addClass(calendar, 'slds-hide');
            return;
        }

        if(phy){
            let selectPhy = component.get('v.physicians')[phy];
            component.find("Specialization__c").set('v.value',selectPhy.Specialization__c);
            component.set('v.selectedPhysician',selectPhy);
            $A.util.removeClass(calendar, 'slds-hide');
        }

        let selectedPhysician = component.get('v.selectedPhysician');
        let email = selectedPhysician.Email;
        var action = component.get("c.getEvents");
        let next = new Date(date);
        next.setDate(next.getDate() + 1);
        let nextDate = next.toISOString().split('T')[0]; 
        let that = this;
        action.setParams({email:email,
                          contextDate : date,
                          nextDate: nextDate});
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                
                let calendar  = $('#calendar').fullCalendar('getCalendar');
                if(!calendar){
                    
                    $('#calendar').fullCalendar({
                        height: 800,
                        events: response.getReturnValue(),
                        timeZone: 'local',
                        defaultView: 'agendaDay',
                        defaultDate: new Date(date), 
                        selectable: true,
                        defaultTimedEventDuration: '00:15:00',
                        minTime: "08:00:00",
                        maxTime: "21:00:00",
                        slotDuration: '00:15:00',
                        slotLabelInterval: 15,
                        slotLabelFormat: 'h(:mm)a',
                        slotEventOverlap:false,
                        header: {
                            center: '',
                            right: ''
                        },
                        businessHours: [{
                            dow: [1, 2, 3, 4, 5], // Monday - Friday
                            start: '08:00',
                            end: '12:00',
                        }, {
                            dow: [1, 2, 3, 4, 5], // Monday - Friday (if adding lunch hours)
                            start: '13:00',
                            end: '21:00',
                        }],
                        selectConstraint: "businessHours",
                        select: function(start, end, jsEvent, view) {
                            if (start.isAfter(moment())) {
                                
                                if(confirm('Comfirm Appointment Booking '+
                                           'with Dr.'+selectedPhysician.Name+
                                           ' at '+ start.format("h(:mm)a") +
                                           '?')){
                                    $("#calendar").fullCalendar('renderEvent', {
                                        start: start,
                                        end: end,
                                        stick: true
                                    });
                                    
                                    that.handleEventCreate(component,start,end,email,selectedPhysician.Id,patient);
                                }
                                
                                
                            } else {
                                alert('Cannot book an appointment in the past');
                            }
                        },
                        eventClick: function(calEvent, jsEvent, view) {
                            alert('Event: ' + calEvent.title);
                        }
                    });
                }
                else{
                    $('#calendar').fullCalendar('gotoDate', new Date(date));
                    $('#calendar').fullCalendar('removeEvents');
                    $('#calendar').fullCalendar('addEventSource', response.getReturnValue());
                }
            }
            else {
                console.log(response.getError());
            }
        });
        $A.enqueueAction(action);
    },
    handleEventCreate : function(component,start,end,email,physicianId,patientId) {
        
        var action = component.get("c.createEvent");
        action.setParams({email: email,
                          patientId : patientId,
                          physicianId: physicianId,
                          startTime : String(start.format()),
                          endTime: String(end.format())});
        
        action.setCallback(this, function(response) {
            if (response.getState() != "SUCCESS") {
                console.log(response.getError());
            }
        });
        $A.enqueueAction(action);
    },
    handlePhysicians: function(component){
        
        let spcl = component.find("Specialization__c").get('v.value');
        let physicians = Object.values(component.get('v.physicians'));
        var availablePhys = physicians.filter(function (phy){
            return (!spcl || spcl == phy.Specialization__c) ;
        });
        let options = [{label: 'None',value:''}];
        availablePhys.forEach(function(phy) {
            options.push({label: phy.Name + (!spcl ? ' ('+phy.Specialization__r.Name+')' : ''),value:phy.Id});
        });
        
        component.find('Physician__c').set('v.options',options);
        component.find("Physician__c").set('v.value','');    
    }
})