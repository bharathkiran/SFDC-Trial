/*Name: DDRERuleController
 *Description: This is a controller for the RuleViewPage and RulePage. This controller has an inner class RERulePackage
 * Date:        - Case#/Project:            - Developer/Company                               - Description
 * ------------------------------------------------------------------------------------------------------------------------- *
 * 12/28/2015   - Fee Rule Engine           - Bharath Ammanamanchi, Deloitte                  - Initial Implementation.
 */
public with sharing class DDRERuleController {
    
    public RERulePackage rulePackage{get;set;}
    public Map<String, Schema.sObjectField> targetFields = new Map<String, Schema.sObjectField>();
    public Integer cRowNum{get;set;}
    public Integer rvRowNum{get;set;}
    public boolean cloneRecord {get;set;}
    
    public DDRERuleController(){
        String ruleID = '';
        cloneRecord = false;
        try{
            rulePackage = new RERulePackage();
            ruleID =ApexPages.CurrentPage().getparameters().get('ruleid'); 
            if(ApexPages.CurrentPage().getparameters().get('clone') == '1'){cloneRecord = true;}
            DDRE_Rule__c rule = new DDRE_Rule__c();
            if(ruleID != ''){
                rule = [Select id, Name, Primary_Object__c, Start_Date__c, End_Date__c, Active__c, CreatedDate, 
                        CreatedById, CreatedBy.Name, LastModifiedBy.Name, LastModifiedDate, LastModifiedById, Description__c,
                        (Select Id,Field_Name__c,Operator__c,Value__c,Active__c,Field_Type__c,Double__c,DTValue__c
                         , Prior_Value__c From DDRE_Criterias__r),
                        (Select Id,DDRE_Value__c,Active__c,DDRE_Value__r.Name From DDRE_Rule_Values__r) 
                        From DDRE_Rule__c WHERE id =:ruleID];
                rulePackage = new RERulePackage(rule, rule.DDRE_Criterias__r, rule.DDRE_Rule_Values__r);
            }
            else{
                rulePackage.rule.Primary_Object__c  = getSObjectTypes().get(0).getLabel();
            }
        }
        catch(Exception e){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Error: Invalid ValueID. <br/>'+e.getMessage());
            ApexPages.addMessage(myMsg);
            
            rulePackage.rule.Primary_Object__c = getSObjectTypes().get(0).getLabel();
        }
    }
    
    public PageReference save(){
        List<sObject> objectsToInsert = new List<sobject>();
        List<sObject> objectsToUpdate = new List<sobject>();
        if(cloneRecord){
            RERulePackage clonerulePackage = rulePackage;
            clonerulePackage.rule.id = null;
            for(DDRE_Criteria__c cri: clonerulePackage.criteriaMap.values()){
                cri.id=null;
            }
            for(DDRE_Rule_Value__c rv: clonerulePackage.ruleValueMap.values()){
                rv.id=null;
            }
            rulePackage = clonerulePackage;
        }
        try{
            if(rulePackage.rule.id == null){
                if(String.isBlank(rulePackage.rule.Name)){
                    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Save Error: Rule Name Required.');
                    ApexPages.addMessage(myMsg);
                    return null;
                }
                insert rulePackage.rule;   
            }
            if(rulePackage.criteriaMap.size() > 0){
                for(DDRE_Criteria__c cri : rulePackage.criteriaMap.values()){
                    if(cri.Value__c != null && cri.Value__c.contains('<Today>')){
                        cri.DTValue__c = null;
                    }
                    if(cri.Id == null){ 
                        cri.DDRE_Rule__c = rulePackage.rule.id;
                        objectsToInsert.add(cri);
                    }
                    else{objectsToUpdate.add(cri);}
                }   
            }
            if(rulePackage.ruleValueMap.size() > 0){
                for(DDRE_Rule_Value__c rv : rulePackage.ruleValueMap.values()){
                    if(rv.Id == null){ 
                        rv.DDRE_Rule__c = rulePackage.rule.id;
                        objectsToInsert.add(rv);
                    }
                    else{objectsToUpdate.add(rv);}
                }
            }
            if(objectsToInsert.size() > 0){ insert objectsToInsert;}
            if(objectsToUpdate.size() > 0){ update objectsToUpdate;}
            PageReference viewPage = new PageReference('/apex/DDRERuleViewPage?ruleid='+rulePackage.rule.id);
            viewPage.setRedirect(true);
            return viewPage;
        }
        catch(Exception e){
            String error = 'ERROR in saving values \n';
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,error+e.getMessage());
            ApexPages.addMessage(myMsg);
            
            return null;
        }
    }
    
    public List<SelectOption> getSObjectTypes(){
        List<SelectOption> sObjectTypes = new List<SelectOption>();
        for(Schema.SObjectType item : ProcessInstance.TargetObjectId.getDescribe().getReferenceTo())  
        {  
            //Excluding custom setting objects  
            if(!item.getDescribe().CustomSetting && item.getDescribe().isUpdateable())
            {  
                //Adding to list  
                sObjectTypes.add(new SelectOption(item.getDescribe().getLocalName() , item.getDescribe().getLabel() ));  
            }  
        }
        sObjectTypes.sort();
        return sObjectTypes;        
    }
    
    public List<SelectOption> getFieldTypes(){
        List<SelectOption> fieldTypeList= new List<SelectOption>();
        targetFields = Schema.getGlobalDescribe().get(rulePackage.rule.Primary_Object__c).getDescribe().fields.getMap();
        for(String key : targetFields.KeySet()){
            fieldTypeList.add(new SelectOption(targetFields.get(key)+'', targetFields.get(key).getDescribe().getLabel()+''));
        }
        fieldTypeList.sort();
        return fieldTypeList;
        
    }
    
    public void setFieldType(){
        try{
            Schema.DisplayType ftype = targetFields.get(rulePackage.criteriaMap.get(cRowNum).Field_Name__c).getDescribe().getType();
            System.debug('**********ftype *************** '+ftype);
            if(ftype ==  Schema.DisplayType.DATE || ftype ==  Schema.DisplayType.DATETIME){
                rulePackage.criteriaMap.get(cRowNum).Field_Type__c = 'Date';
            }
            else if(ftype ==  Schema.DisplayType.INTEGER || ftype ==  Schema.DisplayType.DOUBLE || ftype ==  Schema.DisplayType.PERCENT || ftype ==  Schema.DisplayType.CURRENCY){
                rulePackage.criteriaMap.get(cRowNum).Field_Type__c = 'Double';
            }
            else if(ftype ==  Schema.DisplayType.BOOLEAN){
                rulePackage.criteriaMap.get(cRowNum).Field_Type__c = 'Boolean';
            }
            else {
                rulePackage.criteriaMap.get(cRowNum).Field_Type__c = 'Text';
            }
            System.debug('*****************rulePackage.criteriaMap.get(cRowNum)************'+rulePackage.criteriaMap.get(cRowNum));
        }
        catch(Exception e){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Cannot Delete Row. Error: '+e.getMessage());
            ApexPages.addMessage(myMsg);
            
        }
    }
    
    public void removeCriteriaRow(){
        DDRE_Criteria__c criteriaToRemove = null;
        try{
            if(rulePackage.criteriaMap.get(cRowNum).id != null){
                criteriaToRemove = rulePackage.criteriaMap.get(cRowNum);
                delete criteriaToRemove;
            }
            rulePackage.criteriaMap.remove(cRowNum);
        }
        catch(Exception e){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Cannot Delete Row. Error: '+e.getMessage());
            ApexPages.addMessage(myMsg);
            
        }
    }
    
    public void removeRVRow(){
        DDRE_Rule_Value__c rVToRemove = null;
        try{
            if(rulePackage.ruleValueMap.get(rvRowNum).id != null){
                rVToRemove = rulePackage.ruleValueMap.get(rvRowNum);
                delete rVToRemove;
            }
            rulePackage.ruleValueMap.remove(rvRowNum);
        }
        catch(Exception e){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Cannot Delete Row. Error: '+e.getMessage());
            ApexPages.addMessage(myMsg);
            
        }
    }
    
    public PageReference edit(){
        PageReference viewPage = new PageReference('/apex/DDRERulePage?ruleid='+rulePackage.rule.id);
        viewPage.setRedirect(true);
        return viewPage;
    }
    
    public PageReference cloneRulePackage(){
        PageReference viewPage = new PageReference('/apex/DDRERulePage?ruleid='+rulePackage.rule.id+'&clone=1');
        viewPage.setRedirect(true);
        return viewPage;
    }
    
    /*Name: RERulePackage
    *Description: This is a package class for Value. 
    * Date:        - Case#/Project:            - Developer/Company                            - Description
    * ------------------------------------------------------------------------------------------------------------------------- *
    * 01/08/2016   - Fee Rule Engine           - Bharath Ammanamanchi, Deloitte                  - Initial Implementation.
    */
    public class RERulePackage{
        public DDRE_Rule__c rule{get; set;}
        public Map<Integer, DDRE_Criteria__c> criteriaMap{get;set;}
        public Map<Integer, DDRE_Rule_Value__c> ruleValueMap{get;set;} 
        Integer cRowNum = 0;
        Integer rVRowNum = 0;
        
        public RERulePackage(DDRE_Rule__c rule, List<DDRE_Criteria__c> criteriaList, List<DDRE_Rule_Value__c> rvList){
            
            this.rule = rule;
            criteriaMap = new Map<Integer, DDRE_Criteria__c>();
            for(DDRE_Criteria__c c : criteriaList){
                criteriaMap.put(cRowNum, c);
                cRowNum++;
            }
            
            ruleValueMap = new Map<Integer, DDRE_Rule_Value__c>();
            for(DDRE_Rule_Value__c rv : rvList){
                ruleValueMap.put(rVRowNum, rv);
                rVRowNum++;
            }
            
        }
        
        public RERulePackage(){
            
            rule= new DDRE_Rule__c(Active__c=true);
            criteriaMap = new Map<Integer, DDRE_Criteria__c>();
            ruleValueMap = new Map<Integer, DDRE_Rule_Value__c>();
            
        }
        
        public void addCriteriaRow(){
            criteriaMap.put(cRowNum,new DDRE_Criteria__c(Field_Name__c='Id',Active__c=true,Field_Type__c='Text', Operator__c='Equals'));
            cRowNum++;
        }
        
        public void addrVRow(){
            ruleValueMap.put(rVRowNum, new DDRE_Rule_Value__c(Active__c=true));
            rVRowNum++;
        }
    }
}