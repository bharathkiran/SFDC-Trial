public class objectListViewController {  
    public List<sObject> sObjectRecords{get;set;}
    List<String> fields{get;set;}    
    public Map<String,schema.describefieldresult> Selectedfields{get;set;}
    public objectListViewController(){ 
        Selectedfields=new Map<String,schema.describefieldresult>();
        Map<String,Schema.SObjectField> fieldsDescription;
        String sObjectName;        
            if(ApexPages.currentPage().getParameters().containsKey('sObjectName')){
                sObjectName=ApexPages.currentPage().getParameters().get('sObjectName');
                fieldsDescription=SchemaGlobalDescribe.getFieldDescriptionByObjectName(sObjectName);  
                getFieldsForTable(fieldsDescription);//Set 5 field name
                sObjectRecords=Database.query('Select '+SchemaGlobalDescribe.convertSetToString(Selectedfields.keySet())+' from '+sObjectName);
            }else{
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.FATAL,'Object name not Found!!'));
            }
        
    }
    void getFieldsForTable(Map<String,Schema.SObjectField> fieldsDescription){
        //Replace by Custom Setting pull all fields from custom Setting
        fields=new List<String>();		
        fields.add('ID');   
        fields.add('Name');
        //Replace End
        Set<String> fieldsSet=new Set<String>(fields);
        Integer count=0;
        for(String fieldName:fieldsDescription.keySet()){
            if(!fieldsSet.contains(fieldName)){
                Selectedfields.put(fieldName,(fieldsDescription.get(fieldName)).getDescribe());
            }else if(fieldsSet.contains(fieldName)){
                Selectedfields.put(fieldName,(fieldsDescription.get(fieldName)).getDescribe());
            }
            count++;
            if(count>5)
                break;            
        }
        System.Debug('Selectedfields: '+Selectedfields);
        
    }
}