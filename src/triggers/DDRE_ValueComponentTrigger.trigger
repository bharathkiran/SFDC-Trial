trigger DDRE_ValueComponentTrigger on DDRE_Value_Component__c (after delete, after insert, after update) {
    
        
    Set<id> valueIdSet = new Set<id>();
    List<DDRE_Value_Component__c> valCompList = new List<DDRE_Value_Component__c>();
    if(Trigger.isInsert){
        valCompList = Trigger.new;
    }
    else{
        valCompList = Trigger.old;
    }
    for(DDRE_Value_Component__c vc : valCompList){
        valueIdSet.add(vc.DDRE_Value__c);
    }
    List<DDRE_Value__c> valueListtoUpdate = new List<DDRE_Value__c>();
    
    for(DDRE_Value__c value : [Select id, Description__c,(Select id,Field_API_Name__c, Field_Value__c,Variable_Name__c FROM DDRE_Value_Components__r WHERE Active__c = true) 
                                From DDRE_Value__c Where id IN : valueIdSet]){
        value.Description__c = '';
        
        Double totalPercent = 0.0;
        for(DDRE_Value_Component__c vc : value.DDRE_Value_Components__r){
            if(value.Description__c != ''){
                value.Description__c +='; ';
            }
            
            
            if(vc.Field_API_Name__c == 'Variable'){
                value.Description__c +=' Variable : ';
            }
            value.Description__c += vc.Field_API_Name__c +' --> '+vc.Field_Value__c;                
        }
        valueListtoUpdate.add(value);
    }
    update valueListtoUpdate;    
    
}