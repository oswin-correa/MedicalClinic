({
    doInit: function (component, event, helper) {
        helper.doInit(component);
    },
    handlePhysicians: function (component, event, helper) {
        helper.handlePhysicians(component);
        helper.handleFetchEvents(component);
    },
    handleFetchEvents: function (component, event, helper) {
        helper.handleFetchEvents(component);
    },
});