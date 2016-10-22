public class SchemaGlobalDescribe{
    public static String findObjectNameFromRecordIdPrefix(String recordIdOrPrefix){
        String objectName = '';
        try{
            //Get prefix from record ID
            //This assumes that you have passed at least 3 characters
            String myIdPrefix = String.valueOf(recordIdOrPrefix).substring(0,3);
             
            //Get schema information
            Map<String, Schema.SObjectType> gd =  Schema.getGlobalDescribe(); 
             
            //Loop through all the sObject types returned by Schema
            for(Schema.SObjectType stype : gd.values()){
                Schema.DescribeSObjectResult r = stype.getDescribe();
                String prefix = r.getKeyPrefix();
                System.debug('Prefix is ' + prefix);
                 
                //Check if the prefix matches with requested prefix
                if(prefix!=null && prefix.equals(myIdPrefix)){
                    objectName = r.getName();
                    System.debug('Object Name! ' + objectName);
                    break;
                }
            }
        }catch(Exception e){
            System.debug(e);
        }
        return objectName;
    }
    public static String getAllFieldsByObjectName(String sObjectName){
        return String.join(new List<String>((((Schema.getGlobalDescribe()).get(sObjectName).getDescribe()).fields.getMap()).keyset()), ',');
    }
    public static Map<String,Schema.SObjectField> getFieldDescriptionByObjectName(String sObjectName){
        return ((Schema.getGlobalDescribe()).get(sObjectName).getDescribe()).fields.getMap();
    }
    public static String convertSetToString(Set<String> temp){
        return String.join(new List<String>(temp),',');
    }
        
}