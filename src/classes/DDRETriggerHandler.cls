/*Name: DDRETriggerHandler
 *Description: This is a handler for the Rule Engine. This handler is invoked by the trigger on the sObject.
 * Date:        - Case#/Project:            - Developer/Company                               - Description
 * ------------------------------------------------------------------------------------------------------------------------- *
 * 12/28/2015   - Rule Engine           - Bharath Ammanamanchi, Deloitte                  - Initial Implementation.
 */
public class DDRETriggerHandler {
    
    public static Map<id, sObject> valuePriObjMap = new Map<id, sObject>();
    static Date todayDt = System.today();
    public static Map<String, String> variableMap = new Map<String, String>();
    
    
    /**
    * Method name   : REGeneric
    * Description   : This method checks the criteria and executes the values associated to the criteria. 
    * Return Type   : void
    * Parameter     : String, Map<id, sObject>, Map<id, sObject>
    **/
    public static void REGeneric(String action, Map<id, sObject> newMap, Map<id, sObject> oldMap){
        
        boolean isInsert =false;
        //This value is provided by trigger. 
        if(action == 'Insert'){
            isInsert = true;
        }
        //finding the sobject API Name
        String objName = (newMap.values()).get(0).Id.getSobjectType().getDescribe().getName();
        
        //queries for all the rules which were created on that object. 
        List<DDRE_Rule__c> rules = [SELECT Id, Name, (SELECT Name, Id, Field_Name__c, Value__c,Operator__c,DTValue__c,
                                        Double__c, Field_Type__c,Prior_Value__c FROM DDRE_Criterias__r WHERE Active__c = true),
                                        (Select Id, DDRE_Value__c From DDRE_Rule_Values__r  WHERE Active__c = true)
                                      FROM DDRE_Rule__c WHERE Active__c = true AND Start_Date__c <=: todayDt 
                                    AND (End_Date__c =: null OR End_Date__c >=: todayDt) AND Primary_Object__c=:objName];
        sObject oldObj = null;
        for(sObject newobj : newMap.values()){
            try{
                if(isInsert == false){
                    oldObj = oldMap.get(newobj.Id); 
                }
                for(DDRE_Rule__c r: rules){
                    boolean exitloop = false;
                    boolean isDifferent = false;
                    
                    if((r.DDRE_Criterias__r).size() > 0){
                        for(DDRE_Criteria__c c: r.DDRE_Criterias__r){
                            
                            if(isInsert == false){
                                if((newobj.get(c.Field_Name__c) != oldObj.get(c.Field_Name__c))){
                                    isDifferent = true; 
                                }
                            }
                            boolean criteriaEvaluationResult = true;
                            if(c.Prior_Value__c){
                                if(isInsert == false){criteriaEvaluationResult = (evaluateCriteria(oldObj, c));}
                            }
                            else{
                                criteriaEvaluationResult = (evaluateCriteria(newobj, c));
                            }
                            
                            if(criteriaEvaluationResult == false){
                                exitloop = true;
                                break;
                            }
                        }
                        if(exitloop){
                            continue;
                        }else{
                            
                            if((isDifferent) ||(isInsert)){
                                for(DDRE_Rule_Value__c rv : r.DDRE_Rule_Values__r){
                                    valuePriObjMap.put(rv.DDRE_Value__c, newobj);
                                }
                            }
                        }
                    }
                }
            }
            catch(Exception e){
                String error = 'Cannot process request. Problem with invalid criteria.';
                System.debug((e.getMessage()).center('EXCEPTION'.length()+10,'*'));
                newobj.addError(error +' '+ e.getMessage());
            }
            
        }
        system.debug('******valuePriObjMap.keySet()************'+valuePriObjMap.keySet());
        List<sObject> objectsTobeInsertedList = new List<sObject>();
        if(valuePriObjMap.size() > 0){
            for(DDRE_Value__c val : [Select Id, Object__c, 
                                        (Select Variable_Name__c, Field_API_Name__c, Field_Value__c, Active__c From DDRE_Value_Components__r 
                                            where Active__c = true)                                         
                                        From DDRE_Value__c where Active__c = true AND Start_Date__c <=: todayDt 
                                        AND (End_Date__c =: null OR End_Date__c >=: todayDt)AND id IN : valuePriObjMap.keySet()]){
                //
                sObject primaryObject = valuePriObjMap.get(val.id);
                Schema.SObjectType targetType = Schema.getGlobalDescribe().get(val.Object__c);
                SObject newSobject = targetType.newSObject();
                Map<String, Schema.sObjectField> targetFields = targetType.getDescribe().fields.getMap();
                for(DDRE_Value_Component__c vm : val.DDRE_Value_Components__r){
                    System.debug('*********vm*******'+vm);
                    String value = (vm.Field_Value__c).trim();
                    Schema.DisplayType valueType = null;

                    if(vm.Field_API_Name__c != 'Variable'){
                        System.debug('*********1*******');
                        valueType = targetFields.get(vm.Field_API_Name__c).getDescribe().getType();
                    }
                    if(checkforTagsandOperators(value)){                        
                        value = parseStringWithTag(value, primaryObject, newSobject);
                    }
                    
                    
                    if(vm.Field_API_Name__c == 'Variable'){
                        variableMap.put(vm.Variable_Name__c, value);
                    }
                    if(valueType!= null){
                        if (valueType != Schema.DisplayType.String)
                        {
                            if (valueType == Schema.DisplayType.Date){
                                if(value.contains('<Today>')){
                                    newSobject.put(vm.Field_API_Name__c, evaluavateDate(value));
                                }
                                else{
                                    newSobject.put(vm.Field_API_Name__c, Date.valueOf(value));  
                                }
                            }
                            else if(valueType == Schema.DisplayType.DateTime){
                                Date d = System.Today();
                                if(value.contains('<Today>')){
                                    d = evaluavateDate(value); 
                                }
                                else{
                                    d = Date.valueOf(value);
                                }
                                newSobject.put(vm.Field_API_Name__c, datetime.newInstance(d.year(), d.month(),d.day()));
                            }
                                
                            else if (valueType == Schema.DisplayType.Percent || valueType == Schema.DisplayType.Currency)
                                newSobject.put(vm.Field_API_Name__c, value == '' ? null : Decimal.valueOf(value));
                            else if (valueType == Schema.DisplayType.Double)
                                newSobject.put(vm.Field_API_Name__c, value == '' ? null : Double.valueOf(value));
                            else if (valueType == Schema.DisplayType.Integer)
                                newSobject.put(vm.Field_API_Name__c, Integer.valueOf(value));
                            else if (valueType == Schema.DisplayType.Base64)
                                newSobject.put(vm.Field_API_Name__c, Blob.valueOf(value));
                            else if (valueType == Schema.DisplayType.Boolean)
                                if(value.contains('rue')){
                                    newSobject.put(vm.Field_API_Name__c, true);    
                                }
                                else{
                                    newSobject.put(vm.Field_API_Name__c, false);   
                                }
                                
                            else
                                newSobject.put(vm.Field_API_Name__c, value);
                        }
                        else{
                            newSobject.put(vm.Field_API_Name__c, value);
                        }
                    }
                }
                
                
                if(targetFields.containsKey(objName)){
                    newSobject.put(objName, primaryObject.Id);    
                }
                
                System.debug('*******objectsTobeInsertedList Before*********'+objectsTobeInsertedList);
                objectsTobeInsertedList.add(newSobject);
                System.debug('*******objectsTobeInsertedList after*********'+objectsTobeInsertedList);
                
            }
            valuePriObjMap.clear();
            try{
                insert objectsTobeInsertedList;    
            }
            catch(Exception e){
                
            }
            
        }     
    }     
    
    /**
    * Method name   : parseStringWithTag
    * Description   : 
    * Return Type   : String
    * Parameter     : String, sObject, sObject
    **/
    
    public static String parseStringWithTag(String input, sObject primaryObject, sObject valueObject){
        String value = input;
        try{
            if(value.contains('<m>')){
                String fieldName = value.substringBetween('<m>','</m>');
                value = value.replace(value.substring(value.indexOf('<m>'),value.indexOf('</m>')+4),primaryObject.get(fieldname)+'');
                System.debug(value.center(value.length()+10,'*'));
            }
            if(value.contains('<s>')){
                String fieldName = value.substringBetween('<s>','</s>');
                value = value.replace(value.substring(value.indexOf('<s>'),value.indexOf('</s>')+4),valueObject.get(fieldname)+'');
                System.debug(value.center(value.length()+10,'*'));
            }
            if(value.contains('<v>')){
                String fieldName = value.substringBetween('<v>','</v>');
                value = value.replace(value.substring(value.indexOf('<v>'),value.indexOf('</v>')+4),variableMap.get(fieldname)+'');
                System.debug(value.center(value.length()+10,'*'));
            }
            if(value.contains('<conStr>')){
                String concatString = value.substringBetween('<conStr>','</conStr>');
                for(String s: concatString.split(',')){
                    value += s;
                }
                System.debug(value.center(value.length()+10,'*'));
            }
            else{
                if(value.contains(' ')){
                    double a = Double.valueOf(value.split(' ').get(0));
                    double b = Double.valueOf(value.split(' ').get(2));
                    a = a == null ? 0.00 : a;
                    b = b == null ? 0.00 : b;
                    system.debug((a+'*********'+b).center(value.length()+10,'*'));
                    decimal result = 0.00;
                    if(value.split(' ').get(1) == '+'){
                        result = a + b;
                    }
                    if(value.split(' ').get(1) == '-'){
                        result = a - b;
                    }
                    if(value.split(' ').get(1) == '*'){
                        result = a * b;
                    }
                    if(value.split(' ').get(1) == '/'){
                        result = a / b;
                    }
                    if(value.split(' ').get(1) == '%'){
                        result = (a * b) / 100;
                    }
                    value = (result).setScale(2) + '';
                }    
            }
            
            
            
        }
        catch(Exception e){
            String error = 'Cannot process request. Problem with invalid value.';            
            System.debug((e.getMessage()).center('EXCEPTION'.length()+10,'*'));
            primaryObject.addError(error+e.getMessage());
        }
        return value;
    }
    
    /**
    * Method name   : checkforTagsandOperators
    * Description   : 
    * Return Type   : Boolean
    * Parameter     : String
    **/
    
    public static boolean checkforTagsandOperators(String s){
        if((s.contains('<m>') || s.contains('<s>') || s.contains('<v>') || s.contains(' + ') || s.contains(' - ') || 
                                        s.contains(' * ')|| s.contains(' / ') || s.contains(' % ')) && (!s.contains('<Today>'))){
            return true;
        }
        else{
            return false;
        }
    }
    
    /**
    * Method name   : evaluateCriteria
    * Description   : 
    * Return Type   : Boolean
    * Parameter     : sObject, DDRE_Criteria__c
    **/
    
    public static boolean evaluateCriteria(sObject newObject, DDRE_Criteria__c c){
        boolean returnValue = false;
        System.debug('*************c.Value__c************** '+c.Field_Name__c+'*******'+c.Operator__c+'*******'+c.Value__c);
        System.debug('*************c.DTValue__c************** '+c.Field_Name__c+'*******'+c.Operator__c+'*******'+c.DTValue__c);
        System.debug('*************c.Double__c************** '+c.Field_Name__c+'*******'+c.Operator__c+'*******'+c.Double__c);
        if(String.isNotEmpty(c.Field_Type__c)){c.Field_Type__c = c.Field_Type__c.trim();}
        try{
            if(String.isNotEmpty(c.Value__c) || String.isNotEmpty(String.valueOf(c.DTValue__c)) || String.isNotEmpty(String.valueOf(c.Double__c))){
                if((c.Field_Type__c == 'Text') || (c.Field_Type__c == 'Boolean')){
                    if(c.Operator__c == 'Equals'){if((newObject.get(c.Field_Name__c)+'').toLowerCase() == (c.Value__c).toLowerCase())  returnValue = true;}
                    else if(c.Operator__c == 'Not Equal To'){if((newObject.get(c.Field_Name__c)+'').toLowerCase() != (c.Value__c).toLowerCase())  returnValue = true;}
                    else if(c.Operator__c == 'Contains'){if(((String)newObject.get(c.Field_Name__c)).contains(c.Value__c))  returnValue = true;}
                    else if(c.Operator__c == 'Does Not Contain'){if(!((String)newObject.get(c.Field_Name__c)).contains(c.Value__c))  returnValue = true;}
                    else if(c.Operator__c == 'Starts With'){if(((String)newObject.get(c.Field_Name__c)).startsWith(c.Value__c)) returnValue = true;}
                    else if(c.Operator__c == 'Ends with'){if(((String)newObject.get(c.Field_Name__c)).endsWith(c.Value__c)) returnValue = true;}
                }
                else if(c.Field_Type__c == 'Date'){
                    Schema.DisplayType t = (newObject.Id.getSobjectType().getDescribe().fields.getMap()).get(c.Field_Name__c).getDescribe().getType();
                    Date dtAvalue = (Date)newObject.get(c.Field_Name__c);
                    if(t == Schema.DisplayType.DateTime){
                        Datetime dT = (Datetime)newObject.get(c.Field_Name__c);
                        dtAvalue = date.newinstance(dT.year(), dT.month(), dT.day());
                    }
                    Date dtBvalue = c.DTValue__c;
                    if((c.Value__c).contains('<Today>')){dtBvalue = evaluavateDate(c.Value__c);}
                    if(c.Operator__c == 'Equals'){if(dtAvalue == dtBvalue)  returnValue = true;}
                    else if(c.Operator__c == 'Not Equal To'){if(dtAvalue != dtBvalue)  returnValue = true;}
                    else if(c.Operator__c == 'Greater Than'){if(dtAvalue > dtBvalue)  returnValue = true;}
                    else if(c.Operator__c == 'Greater Or Equal'){if(dtAvalue >= dtBvalue)  returnValue = true;}
                    else if(c.Operator__c == 'Less Than'){if(dtAvalue < dtBvalue)  returnValue = true;}
                    else if(c.Operator__c == 'Less Or Equal'){if(dtAvalue <= dtBvalue)  returnValue = true;}
                }
                else if(c.Field_Type__c == 'Double'){
                    String intValue = ((c.Double__c+'').contains('.00')) ? (c.Double__c+'').substringBefore('.') : (c.Double__c+'');
                    System.debug('***************intValue***********'+intValue);
                    if(c.Operator__c == 'Equals'){if(((Double)newObject.get(c.Field_Name__c)) == (c.Double__c))  returnValue = true;}
                    else if(c.Operator__c == 'Not Equal To'){if(((Double)newObject.get(c.Field_Name__c)) != (c.Double__c))  returnValue = true;}
                    else if(c.Operator__c == 'Contains'){if((((Double)newObject.get(c.Field_Name__c))+'').contains(intValue))  returnValue = true;}
                    else if(c.Operator__c == 'Does Not Contain'){if(!(((Double)newObject.get(c.Field_Name__c))+'').contains(intValue))  returnValue = true;}
                    else if(c.Operator__c == 'Starts With'){if((((Double)newObject.get(c.Field_Name__c))+'').startsWith(intValue))  returnValue = true;}
                    else if(c.Operator__c == 'Ends with'){if((((Double)newObject.get(c.Field_Name__c))+'').endsWith(intValue))  returnValue = true;}
                    else if(c.Operator__c == 'Greater Than'){if(((Double)newObject.get(c.Field_Name__c)) > (c.Double__c))  returnValue = true;}
                    else if(c.Operator__c == 'Greater Or Equal'){if(((Double)newObject.get(c.Field_Name__c)) >= (c.Double__c))  returnValue = true;}
                    else if(c.Operator__c == 'Less Than'){if(((Double)newObject.get(c.Field_Name__c)) < (c.Double__c))  returnValue = true;}
                    else if(c.Operator__c == 'Less Or Equal'){if(((Double)newObject.get(c.Field_Name__c)) <= (c.Double__c))  returnValue = true;}
                }
            }
            else{
                if(c.Operator__c == 'Equals'){if(newObject.get(c.Field_Name__c) == null)  returnValue = true;}
                else if(c.Operator__c == 'Not Equal To'){if(newObject.get(c.Field_Name__c) != null)  returnValue = true;}
            }
        }
        catch(Exception e){
            String error = 'Cannot process request. Problem with invalid criteria: '+c.Name + ' '+ e.getMessage();
            System.debug((e.getMessage()).center('EXCEPTION'.length()+10,'*'));
            newObject.addError(error);
        }
        System.debug('*************returnValue**************'+returnValue);
        return returnValue;
    }
    
    /**
    * Method name   : evaluavateDate
    * Description   : 
    * Return Type   : Date
    * Parameter     : String
    **/
    
    public static Date evaluavateDate(String inValue){
        Date todayDate = System.today();
        if(inValue.contains(' ')){
            Integer numOfDays = Integer.valueOf(inValue.split(' ').get(2));        
            if(inValue.split(' ').get(1) == '-'){
                numOfDays = -numOfDays;
            }
            todayDate = todayDate.addDays(numOfDays);
        }
        return todayDate;
    }
    
}