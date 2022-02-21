import { LightningElement } from 'lwc';
import getProductsByPriceBook from '@salesforce/apex/LTNG_ProductCatalog_Controller.getProductsByPriceBook';

export default class cmp_wishlistedProducts extends LightningElement {
    priceBookName = 'Dmart Pricebook';
    productList = [];
    connectedCallback(){
        this.handleGetProductRecords();
    }
    handleGetProductRecords(){
        getProductsByPriceBook({ priceBookName : this.priceBookName})
        .then (result => {
            this.productList = result;           
        })
        .catch(error => {
            console.error('Error occured while fetching Product records -> '+JSON.stringify(error));
        });
    }
}