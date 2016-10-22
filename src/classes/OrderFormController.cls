public class OrderFormController{

    public String orderId = '';
    public Order__c order{get;set;}
    public Map<Integer, LineItemWrapper> lineItemMap{get;set;}
    public Integer lineItemNum ;
    public OrderFormController(){
        lineItemNum  = 0;
        lineItemMap = new Map<Integer, LineItemWrapper>();
        orderId = ApexPages.currentPage().getParameters().get('oid');
        order = [Select id, Name from Order__c Where id=:orderId ];
        
        for(Line_Item__c li : [Select id, Name, Discount__c, Quantity__c, Product__c, Product__r.Price__c From Line_Item__c Where Order__c =: order.id]){
            lineItemMap.put(lineItemNum , new LineItemWrapper(li, false));
        }
        if(lineItemMap.size() == 0){
            lineItemMap.put(lineItemNum , new LineItemWrapper(new Line_Item__c(), true));
        }
    }
    
    public List<SelectOption> getProducts() {
        List<SelectOption> options = new List<SelectOption>();
        for(Product__c p : [Select id, Name From Product__c]){
            options.add(new SelectOption(p.Id,p.Name));
        }
        return options;
    }
    
    public void addNewLineItem(){
    
    }
    
    public void makeEditable(){
        
    }


    public class LineItemWrapper{
        public Line_Item__c lineItem{get;set;}
        public boolean isSaveVisible{get;set;}
        
        public LineItemWrapper(){
        
        }
        
        public LineItemWrapper(Line_Item__c lineItem, boolean isSaveVisible){
            this.lineItem = lineItem;
            this.isSaveVisible = isSaveVisible;
        }
        
        
    }
}