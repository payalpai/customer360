import { LightningElement, api } from 'lwc';
import getOrdersByAccount from '@salesforce/apex/LTNG_ProductCatalog_Controller.getOrdersByAccount';

const columns = [
    { label: 'Item Number', fieldName: 'orderItemNumber',  type:'text', hideDefaultActions: 'true'},
    { label: 'Product Name', fieldName: 'orderItemProductName',  type:'text', hideDefaultActions: 'true'},
    { label: 'Quantity', fieldName: 'orderItemQuantity',  type:'number', hideDefaultActions: 'true'},
    { label: 'Unit Price', fieldName: 'orderItemUnitPrice',  type:'number', hideDefaultActions: 'true'},
    { label: 'Item Total Price', fieldName: 'orderItemTotalPrice',  type:'number', hideDefaultActions: 'true'}
];

export default class cmp_viewOpenOrders extends LightningElement {
    @api accountId;
    ordersList = [];
    columns = columns;

    connectedCallback(){
        this.handleGetOrders();
    }

    handleGetOrders(){
        getOrdersByAccount({accountId : this.accountId})
        .then (result => {
            this.ordersList = result;
        })
        .catch(error => {
            console.error('Error occured while fetching PriceBook records -> '+JSON.stringify(error));
        });
    }
}