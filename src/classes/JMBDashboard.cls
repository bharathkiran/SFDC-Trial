public with sharing class JMBDashboard {

    // Code from https://www.salesforce.com/us/developer/docs/apexcode/Content/apex_dynamic_describeTabs.htm
    // Get tab set describes for each app
    List<Schema.DescribeTabSetResult> tabSetDesc = Schema.describeTabs();

    public class TabLinks {
        public String linkname {
            get {return linkname; }
            set {linkname = value; }                        
        }
        public String linkurl {
            get {return linkurl; }
            set {linkurl = value; }                     
        }  
        public String sObjectName{
            get {return sObjectName; }
            set {sObjectName = value; }
        }
    }
    
    public class AppLinks{
    	
    	public String linkname {
            get {return linkname; }
            set {linkname = value; }                        
        }
        public String linkurl {
            get {return linkurl; }
            set {linkurl = value; }                     
        } 
    }

    public static List<TabLinks> getTabs() {
        
        List<TabLinks> appTabs = new List<TabLinks>();
                
        Schema.DescribeTabSetResult[] tabSetDesc = Schema.describeTabs();
                
        // Iterate through each tab set describe for each app and display the info
        for(DescribeTabSetResult tsr : tabSetDesc) {
            String appLabel = tsr.getLabel();
            System.debug('*******Label: ' + appLabel);
            System.debug('*****Logo URL: ' + tsr.getLogoUrl());
            System.debug('*******isSelected: ' + tsr.isSelected());
            String ns = tsr.getNamespace();
            if (ns == '') {
                System.debug('The ' + appLabel + ' app has no namespace defined.');
            }
            else {
                System.debug('Namespace: ' + ns);
            }
            
            // Display tab info for the Sales app
            // replace with your app name here
            if (appLabel == 'Order Management') {
                List<Schema.DescribeTabResult> tabDesc = tsr.getTabs();
                System.debug('-- Tab information for the Sales app --');
                for(Schema.DescribeTabResult tr : tabDesc) {
                    TabLinks myDetail = new TabLinks();                 
                    myDetail.linkname = tr.getLabel();
                    myDetail.linkurl = tr.getUrl();
                    myDetail.sObjectName=tr.getsObjectName();
                    appTabs.add(myDetail);
                }
                
                return appTabs;
            }            
        }
        
        return appTabs;
    }
}