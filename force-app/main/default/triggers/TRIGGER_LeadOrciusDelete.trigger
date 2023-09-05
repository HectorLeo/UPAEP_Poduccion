trigger TRIGGER_LeadOrciusDelete on Lead (after insert) {
    List<Id> deleteList = new List<Id>();
    
    for(Lead obj: Trigger.new) {
        if (obj.Texto_programa__c == 'ELIMINAR - ES UN INTERESADO ORCIUS DUPLICADO'){
            deleteList.add( obj.id );
        }
    }
    
    if( deleteList.size() > 0) { Database.delete(deleteList); }
}