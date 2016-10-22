trigger DDRE_CriteriaTrigger on DDRE_Criteria__c (after delete, after insert, after update) {
    
    Set<id> ruleIdSet = new Set<id>();
    List<DDRE_Criteria__c> criteriaList = new List<DDRE_Criteria__c>();
    if(Trigger.isInsert){
    	criteriaList = Trigger.new;
    }
    else{
    	criteriaList = Trigger.old;
    }
    for(DDRE_Criteria__c c : criteriaList){
    	ruleIdSet.add(c.DDRE_Rule__c);
    }
    List<DDRE_Rule__c> ruleListtoUpdate = new List<DDRE_Rule__c>();
    for(DDRE_Rule__c rule : [Select id, Description__c,(Select id,Field_Name__c, Value__c,Operator__c,DTValue__c,
        								Double__c, Field_Type__c,Prior_Value__c FROM DDRE_Criterias__r WHERE Active__c = true) From DDRE_Rule__c Where id IN:ruleIdSet]){
    	rule.Description__c = '';
    	Integer listSize = 0;
    	for(DDRE_Criteria__c c : rule.DDRE_Criterias__r){
    		if(listSize >0){
    			rule.Description__c +=' <AND> ';
    		}
    			
    		if(c.Prior_Value__c){
    			rule.Description__c +='PRIOR_VALUE('+c.Field_Name__c+') ';
    		}else{
    			rule.Description__c +=c.Field_Name__c;
    		}
    		
    		if((c.Field_Type__c == 'Text') || (c.Field_Type__c == 'Boolean')){
    			rule.Description__c += ' '+ c.Operator__c+' '+c.Value__c;
    		}
    		if(c.Field_Type__c == 'Double'){
    			rule.Description__c += ' '+ c.Operator__c+' '+c.Double__c;
    		}
    		if(c.Field_Type__c == 'Date'){
    			if(String.isNotBlank(c.Value__c)){
    				rule.Description__c += ' '+ c.Operator__c+' '+c.Value__c;
    			}else{
    				rule.Description__c += ' '+ c.Operator__c+' '+c.DTValue__c;
    			}
    		}
    		listSize++;
    	}
    	ruleListtoUpdate.add(rule);
    }
    update ruleListtoUpdate;
}