public with sharing class LTNG_ProductCatalog_Controller {

    /* Fetch Pricebook Records */
    @AuraEnabled
    public static List<PriceBookWrapper> getPriceBookRecords(){
        List<PriceBookWrapper> priceBookWrapperList = new List<PriceBookWrapper>();
        List<Pricebook2> priceBookList = [SELECT Id, Name FROM Pricebook2 LIMIT 500];
        PriceBookWrapper priceBookWrapperRecord;
        for(Pricebook2 priceBookRecord : priceBookList){
            priceBookWrapperRecord = new PriceBookWrapper();
            priceBookWrapperRecord.label = priceBookRecord.Name;
            priceBookWrapperRecord.value = priceBookRecord.Name;
            priceBookWrapperList.add(priceBookWrapperRecord);
        }
        return priceBookWrapperList;
    }
    public class PriceBookWrapper {
        @AuraEnabled public String label {get; set;}
        @AuraEnabled public String value {get; set;}
    }

    /* Fetch Products Records based on the selected Pricebook */
    @AuraEnabled
    public static List<ProductWrapper> getProductsByPriceBook(String priceBookName){
        List<ProductWrapper> productWrapperList = new List<ProductWrapper>();
        List<PricebookEntry> priceBookEntryList = [SELECT Id, Product2Id, Product2.Name, product2.ProductCode, UnitPrice, Product2.Product_Image__c
                                                    FROM PricebookEntry 
                                                    WHERE Pricebook2.Name = :priceBookName];
        ProductWrapper productWrapperRecord;
        for(PricebookEntry priceBookEntryRecord : priceBookEntryList){
            productWrapperRecord = new ProductWrapper();
            productWrapperRecord.productImage = priceBookEntryRecord.Product2.Product_Image__c;
            productWrapperRecord.productName = priceBookEntryRecord.Product2.Name;
            productWrapperRecord.productCode = priceBookEntryRecord.product2.ProductCode;
            productWrapperRecord.productListPrice = priceBookEntryRecord.UnitPrice;
            productWrapperRecord.productId = priceBookEntryRecord.Id;
            productWrapperRecord.productInCart = false;
            productWrapperRecord.productQuantityInCart = 0;
            productWrapperList.add(productWrapperRecord);
        }
        return productWrapperList;
    }
    /* Wrapper for sending Product details to LWC */
    public class ProductWrapper {
        @AuraEnabled public String productId {get; set;}
        @AuraEnabled public String productImage {get; set;}
        @AuraEnabled public String productName {get; set;}
        @AuraEnabled public String productCode {get; set;}
        @AuraEnabled public Decimal productListPrice {get; set;}
        @AuraEnabled public Boolean productInCart {get; set;}
        @AuraEnabled public Integer productQuantityInCart {get; set;}
    }

    /* Place order with all the products in cart */
    @AuraEnabled 
    public static String placeOrder(List<ProductWrapper> placeOrderList, String accountId, String selectedPricebook){
        Database.Saveresult saveResult;
        if(placeOrderList != null){
            Order orderRecord = new Order();
            Account relatedAccountRecord = [SELECT Id, Name FROM Account WHERE Id = :accountId LIMIT 1];
            orderRecord.AccountId = relatedAccountRecord.Id;
            Pricebook2 priceBookRecord = [SELECT Id, Name FROM Pricebook2 WHERE Name = :selectedPricebook LIMIT 1];
            orderRecord.Pricebook2Id = priceBookRecord.Id;
            orderRecord.EffectiveDate = System.Today();
            orderRecord.Status = 'Created';
            orderRecord.Name = 'DMart order for ' + relatedAccountRecord.Name;
            try{
                saveResult = Database.insert(orderRecord);
            }
            catch(DmlException ex){
                system.debug('Error Creating Order Record : '+ ex.getMessage() +' Stacktrace : '+ex.getStackTraceString());
                return 'error';
            }
            if(saveResult.isSuccess()){  
                List<OrderItem> orderItemsList = new List<OrderItem>();
                OrderItem orderItemRecord;
                for(ProductWrapper placeOrderRecord : placeOrderList){
                        orderItemRecord = new OrderItem();
                        orderItemRecord.OrderId = orderRecord.Id;
                        orderItemRecord.UnitPrice = placeOrderRecord.productListPrice;
                        orderItemRecord.Quantity = placeOrderRecord.productQuantityInCart;
                        orderItemRecord.Product2Id = placeOrderRecord.productId;
                        orderItemsList.add(orderItemRecord);
                }
                try{
                    insert orderItemsList;
                }
                catch(DmlException ex){
                    system.debug('Error Creating Order Line Item Records : '+ ex.getMessage() +' Stacktrace : '+ex.getStackTraceString());
                    return 'error';
                }
            }
            Order orderRecord1 = new Order();
            orderRecord1 = [SELECT Id, OrderNumber FROM Order WHERE Id = : orderRecord.Id];
            return 'Order created with Order Number : '+orderRecord1.OrderNumber +'.\n';
        }
        return 'error';
    }
    /* Parent Wrapper for Orders */
    public class OrderWrapper {
        @AuraEnabled public String orderNumber {get; set;}
        @AuraEnabled public String orderName {get; set;}
        @AuraEnabled public Decimal orderTotal {get; set;}
        @AuraEnabled public List<OrderItemsWrapper> orderItemsList {get; set;}
    }
    /* Wrapper for Order Line Items  */
    public class OrderItemsWrapper {
        @AuraEnabled public String orderItemNumber {get; set;}
        @AuraEnabled public String orderItemProductName {get; set;}
        @AuraEnabled public Decimal orderItemQuantity {get; set;}
        @AuraEnabled public Decimal orderItemUnitPrice {get; set;}
        @AuraEnabled public Decimal orderItemTotalPrice {get; set;}
    }
    /* Fetch All Orders created specific to the Account */
    @AuraEnabled
    public static List<OrderWrapper> getOrdersByAccount(String accountId){
        List<OrderWrapper> orderWrapperList = new List<OrderWrapper>();
        Map<Id, List<OrderItemsWrapper>> orderItemMap = new Map<Id, List<OrderItemsWrapper>>();

        List<Order> ordersList = [SELECT Id, Name, OrderNumber, Total_Amount__c
                                    FROM Order 
                                    WHERE AccountId = :accountId ORDER BY CreatedDate DESC];
       
        List<OrderItem> orderItemsList = [SELECT Id, OrderId, OrderItemNumber, Product2.Name, Quantity, UnitPrice, TotalPrice 
                                            FROM OrderItem 
                                            WHERE OrderId IN :ordersList];

        OrderItemsWrapper orderItemsWrapperRecord;
        List<OrderItemsWrapper> orderItemsWrapperList; 
        for(OrderItem orderItemRecord : orderItemsList){
            orderItemsWrapperRecord = new OrderItemsWrapper();
            orderItemsWrapperRecord.orderItemNumber = orderItemRecord.OrderItemNumber;
            orderItemsWrapperRecord.orderItemProductName = orderItemRecord.Product2.Name;
            orderItemsWrapperRecord.orderItemQuantity = orderItemRecord.Quantity;
            orderItemsWrapperRecord.orderItemUnitPrice = orderItemRecord.UnitPrice;
            orderItemsWrapperRecord.orderItemTotalPrice = orderItemRecord.TotalPrice;
            if(orderItemMap.get(orderItemRecord.OrderId) != null){
                orderItemsWrapperList = new List<OrderItemsWrapper>();
                orderItemsWrapperList = orderItemMap.get(orderItemRecord.OrderId);
                orderItemsWrapperList.add(orderItemsWrapperRecord);
                orderItemMap.put(orderItemRecord.OrderId, orderItemsWrapperList);
            }
            else{
                orderItemMap.put(orderItemRecord.OrderId, new List<OrderItemsWrapper> {orderItemsWrapperRecord});
            }
        }

        OrderWrapper orderWrapperRecord; 
        for(Order orderRecord : ordersList){
            orderWrapperRecord = new OrderWrapper();
            orderWrapperRecord.orderNumber = orderRecord.OrderNumber;
            orderWrapperRecord.orderName = orderRecord.Name;
            orderWrapperRecord.orderTotal = orderRecord.Total_Amount__c;
            orderWrapperRecord.orderItemsList = orderItemMap.get(orderRecord.Id);
            orderWrapperList.add(orderWrapperRecord);
        }
        return orderWrapperList;
    }
    /* Wrapper for Products present In Cart */
    public class InCartWrapper {
        @AuraEnabled public List<ProductWrapper> productWrapperList {get; set;}
        @AuraEnabled public Decimal productTotalPrice {get; set;}
        @AuraEnabled public Decimal productTotalQuantity {get; set;}
    }

    /* Fetch all products present In Cart */
    @AuraEnabled
    public static InCartWrapper getInCartProducts(){
        InCartWrapper inCartWrapper = new InCartWrapper();
        List<ProductWrapper> cartWrapperList = new List<ProductWrapper>();
        ProductWrapper cartWrapperRecord;
        List<In_Cart__c> inCartList = [SELECT Id, ProductId__c, Product_Name__c, Product_Image__c, Product_List_Price__c, Product_Quantity__c
                                                    FROM In_Cart__c];
        if(inCartList.size() > 0){
            for(In_Cart__c inCartRec : inCartList){
                cartWrapperRecord = new ProductWrapper();
                cartWrapperRecord.productId = inCartRec.ProductId__c;
                cartWrapperRecord.productImage = inCartRec.Product_Image__c;
                cartWrapperRecord.productName = inCartRec.Product_Name__c;
                cartWrapperRecord.productListPrice = inCartRec.Product_List_Price__c;
                cartWrapperRecord.productQuantityInCart = (Integer) inCartRec.Product_Quantity__c;
                cartWrapperList.add(cartWrapperRecord);
            }
        }
        List<AggregateResult> aggResult = [SELECT SUM(Product_Total_Price__c), SUM(Product_Quantity__c) FROM In_Cart__c]; 
        inCartWrapper.productWrapperList = cartWrapperList;
        inCartWrapper.productTotalPrice = (Decimal)aggResult[0].get('expr0');
        inCartWrapper.productTotalQuantity = (Decimal)aggResult[0].get('expr1');

        return inCartWrapper;
    }

    /* Add selected product to cart */
    @AuraEnabled
    public static Boolean addToCart(String productId, Integer quantitySelected){
        PricebookEntry priceBookEntryRecord = [SELECT Id, Product2Id, Product2.Name, UnitPrice, Product2.Product_Image__c
                                                    FROM PricebookEntry 
                                                    WHERE Id = :productId
                                                    LIMIT 1];
        List<In_Cart__c> inCartList = [SELECT Id, ProductId__c, Product_Name__c, Product_Image__c, Product_List_Price__c, Product_Quantity__c
                                            FROM In_Cart__c
                                            WHERE ProductId__c = :productId];
        In_Cart__c inCartRecord = new In_Cart__c();
        if(inCartList.size() > 0){
            inCartRecord = inCartList[0];  
            if(quantitySelected!= null){
                inCartRecord.Product_Quantity__c = quantitySelected;
            }
            else{
                inCartRecord.Product_Quantity__c += 1;  
            }                   
        }
        else{
            inCartRecord.ProductId__c = priceBookEntryRecord.Id; 
            inCartRecord.Product_Image__c = priceBookEntryRecord.Product2.Product_Image__c; 
            inCartRecord.Product_Name__c = priceBookEntryRecord.Product2.Name; 
            inCartRecord.Product_List_Price__c = priceBookEntryRecord.UnitPrice; 
            inCartRecord.Product_Quantity__c = 1;
        }
        try{
            upsert inCartRecord;
           
        }
        catch(Exception ex){
            System.debug('Error Adding In Cart Records : '+ ex.getMessage() +' Stacktrace : '+ex.getStackTraceString());
            return false;
        }
        return true;
    }

    /* Remove selected product to cart */
    @AuraEnabled
    public static Boolean removeFromCart(String productId, Boolean removeAll){
        List<In_Cart__c> inCartList;
        if(removeAll){
            inCartList = [SELECT Id, ProductId__c, Product_Name__c, Product_Image__c, Product_List_Price__c, Product_Quantity__c
                                    FROM In_Cart__c];
        }
        else{
            inCartList = [SELECT Id, ProductId__c, Product_Name__c, Product_Image__c, Product_List_Price__c, Product_Quantity__c
                                    FROM In_Cart__c
                                    WHERE ProductId__c = :productId];
        }
        try{
            if(removeAll){
                delete inCartList;
            }
            else{
                delete inCartList[0];
            }
        }
        catch(Exception ex){
            System.debug('Error Removing In Cart Records : '+ ex.getMessage() +' Stacktrace : '+ex.getStackTraceString());
            return false;
        }
        return true;
    }
    

}