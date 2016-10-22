/*Name: DDREValueController
 *
 : This is a controller for the ValueViewPage and ValuePage. This controller has an inner class DDREValuePackage
 * Date:        - Case#/Project:            - Developer/Company                               - Description
 * ------------------------------------------------------------------------------------------------------------------------- *
 * 12/28/2015   - Rule Engine           - Bharath Ammanamanchi, Deloitte                  - Initial Implementation.
 */
public with sharing class DDREValueController {
    
    public DDREValuePackage valuepackage{get;set;}
    public Map<String, Schema.sObjectField> targetFields = new Map<String, Schema.sObjectField>();
    public Integer vcRowNum{get;set;}
    public Integer rvRowNum{get;set;}    
    public boolean cloneRecord {get;set;}
    public String fieldAPIName{get;set;}
    
    public DDREValueController(){
        String valueID = '';
        cloneRecord = false;
        
        try{
            valuepackage = new DDREValuePackage();
            valueID =ApexPages.CurrentPage().getparameters().get('valueid'); 
            if(ApexPages.CurrentPage().getparameters().get('clone') == '1'){cloneRecord = true;}
            DDRE_Value__c value = new DDRE_Value__c();
            if(valueID != ''){
                value = [Select Start_Date__c, Object__c, Name, LastModifiedDate, LastModifiedById, Id,Master_Object__c, 
                        End_Date__c, CreatedDate, CreatedById, CreatedBy.Name, LastModifiedBy.Name, Active__c, Description__c,
                        (Select Id, DDRE_Value__c, Active__c, Field_API_Name__c, Field_Value__c,Variable_Name__c From DDRE_Value_Components__r),                         
                        (Select Id,DDRE_Rule__c,Active__c,DDRE_Rule__r.Name From DDRE_Rule_Values__r)
                        From DDRE_Value__c WHERE id =:valueID]; 
                valuepackage = new DDREValuePackage(value, value.DDRE_Value_Components__r, value.DDRE_Rule_Values__r);                
            }
            else{
                valuepackage.value.Object__c = getSObjectTypes().get(0).getLabel();
                valuepackage.value.Master_Object__c = getSObjectTypes().get(0).getLabel();
            }
        }
        catch(Exception e){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Error: Invalid ValueID. <br/>'+e.getMessage());
            ApexPages.addMessage(myMsg);            
            valuepackage.value.Object__c = getSObjectTypes().get(0).getLabel();
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
    
    public List<SelectOption> getVCFieldTypes(){
        List<SelectOption> fieldTypeList= new List<SelectOption>{new SelectOption('Variable','--Variable--')};
        targetFields = Schema.getGlobalDescribe().get(valuepackage.value.Object__c).getDescribe().fields.getMap();
        for(String key : targetFields.KeySet()){
            fieldTypeList.add(new SelectOption(targetFields.get(key).getDescribe().getLocalName(), targetFields.get(key).getDescribe().getLabel()+''));
        }
        fieldTypeList.sort();
        return fieldTypeList;
        
    }
    
    public List<SelectOption> getFieldTypes(){
        List<SelectOption> fieldTypeList= new List<SelectOption>();
        Map<String, Schema.sObjectField> targetFieldsdisp = Schema.getGlobalDescribe().get(valuepackage.value.Master_Object__c).getDescribe().fields.getMap();
        for(String key : targetFieldsdisp.KeySet()){
            Schema.DisplayType ftype = targetFieldsdisp.get(key).getDescribe().getType();
            if(ftype ==  Schema.DisplayType.INTEGER || ftype ==  Schema.DisplayType.DOUBLE || ftype ==  Schema.DisplayType.PERCENT || ftype ==  Schema.DisplayType.CURRENCY || ftype ==  Schema.DisplayType.Reference){
                fieldTypeList.add(new SelectOption('<m>'+targetFieldsdisp.get(key).getDescribe().getLocalName()+'</m> (Field Type: '+ftype+')', targetFieldsdisp.get(key).getDescribe().getLabel()+''));
            }           
        }
        fieldTypeList.sort();
        return fieldTypeList;
        
    }
    
    public void removeVCRow(){
        DDRE_Value_Component__c valToRemove = null;
        try{
            if(valuepackage.valueComponentsMap.get(vcRowNum).id != null){
                valToRemove = valuepackage.valueComponentsMap.get(vcRowNum);
                delete valToRemove;
            }
            valuepackage.valueComponentsMap.remove(vcRowNum);
        }
        catch(Exception e){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Cannot Delete Row. Error: '+e.getMessage());
            ApexPages.addMessage(myMsg);            
        }
    }
    
    public PageReference save(){
        List<sObject> objectsToInsert = new List<sobject>();
        List<sObject> objectsToUpdate = new List<sobject>();
        if(cloneRecord){
            DDREValuePackage cloneValuePackage = valuepackage;
            cloneValuePackage.value.id = null;
            for(DDRE_Value_Component__c vc: cloneValuePackage.valueComponentsMap.values()){
                vc.id=null;
            }            
            valuepackage = cloneValuePackage;
        }
        try{
            if(valuepackage.value.id == null){
                if(String.isBlank(valuepackage.value.Name)){
                    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Save Error: Value Name Required.');
                    ApexPages.addMessage(myMsg);
                    return null;
                }
                insert valuepackage.value;   
            }
            if(valuepackage.valueComponentsMap.size() > 0){
                for(DDRE_Value_Component__c vc : valuepackage.valueComponentsMap.values()){
                    
                    if(vc.Id == null){ 
                        vc.DDRE_Value__c = valuepackage.value.id;
                        objectsToInsert.add(vc);}
                    else{objectsToUpdate.add(vc);}
                }   
            }
            if(objectsToInsert.size() > 0){ insert objectsToInsert;}
            if(objectsToUpdate.size() > 0){ update objectsToUpdate;}
            PageReference viewPage = new PageReference('/apex/DDREValueViewPage?valueid='+valuepackage.value.id);
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
    
    public PageReference edit(){
        PageReference viewPage = new PageReference('/apex/DDREValuePage?valueid='+valuepackage.value.id);
        viewPage.setRedirect(true);
        return viewPage;
    }
    
    public PageReference cancel(){
        PageReference viewPage = new PageReference('/apex/DDREValueViewPage?valueid='+valuepackage.value.id);
        viewPage.setRedirect(true);
        return viewPage;
    }
    
    public PageReference clonevaluePackage(){
        PageReference viewPage = new PageReference('/apex/DDREValuePage?valueid='+valuepackage.value.id+'&clone=1');
        viewPage.setRedirect(true);
        return viewPage;
    }
    
    /*Name: DDREValuePackage
    *Description: This is a package class for Value. 
    * Date:        - Case#/Project:            - Developer/Company                            - Description
    * ------------------------------------------------------------------------------------------------------------------------- *
    * 01/28/2015   - Rule Engine               - Bharath Ammanamanchi, Deloitte                  - Initial Implementation.
    */
    public class DDREValuePackage{
        public DDRE_Value__c value{get; set;}
        public Map<Integer, DDRE_Value_Component__c> valueComponentsMap{get;set;}
        public Map<Integer, DDRE_Rule_Value__c> ruleValueMap{get;set;}
        Integer vCRowNum = 0;        
        Integer rVRowNum = 0;
        
        public DDREValuePackage(DDRE_Value__c val, List<DDRE_Value_Component__c> vcList, List<DDRE_Rule_Value__c> rvList){
            
            this.value = val;
            valueComponentsMap = new Map<Integer, DDRE_Value_Component__c>();
            for(DDRE_Value_Component__c vc : vcList){
                valueComponentsMap.put(vCRowNum, vc);
                vCRowNum++;
            }
                        
            ruleValueMap = new Map<Integer, DDRE_Rule_Value__c>();
            for(DDRE_Rule_Value__c rv : rvList){
                ruleValueMap.put(rVRowNum, rv);
                rVRowNum++;
            }
            
        }
        
        public DDREValuePackage(){
            value= new DDRE_Value__c(Active__c=true);
            valueComponentsMap = new Map<Integer, DDRE_Value_Component__c>();
            addvcRow();
            ruleValueMap = new Map<Integer, DDRE_Rule_Value__c>();
            
        }
        
        public void addvcRow(){
            valueComponentsMap.put(vCRowNum,new DDRE_Value_Component__c(Active__c=true));
            vCRowNum++;
        }
        
        public void addrVRow(){
            ruleValueMap.put(rVRowNum, new DDRE_Rule_Value__c(Active__c=true));
            rVRowNum++;
        }
        
    }
}