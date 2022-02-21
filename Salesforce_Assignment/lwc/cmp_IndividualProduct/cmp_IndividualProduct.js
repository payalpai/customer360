import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import addToCart from '@salesforce/apex/LTNG_ProductCatalog_Controller.addToCart';
import getInCartProducts from '@salesforce/apex/LTNG_ProductCatalog_Controller.getInCartProducts';


export default class cmp_IndividualProduct extends LightningElement {
    @api productList;
    @api accountId;
    @api selectedPricebook;
    addedInCartCountMap = new Map();
    totalCost = 0;
    showCart = false;
    showModal = false;
    showSpinner = false;
    inCartList = [];
    cartItemCount = 0;
    get productColumnSize(){
        if(this.showCart){
            return 'slds-col slds-size_3-of-5';
        }
        return 'slds-col slds-size_5-of-5';
    }

    connectedCallback(){
        this.handleGetInCartRecords();
    }
    
    handleAddToCart(event){
        this.showCart = false;
        let addedToCartId = event.currentTarget.dataset.index;
        this.showSpinner = true;
        addToCart({productId : addedToCartId})
        .then(result => {
            if(result){
                this.showToast('Added to Cart', 'Product Added To Cart Successfully.', 'success');
                this.handleGetInCartRecords();
                this.showSpinner = false;
                this.showCart = true;
            }
        })
        .catch(error => {
            console.error('Error occured while adding in cart records -> '+JSON.stringify(error));
            this.showSpinner = false;
        });
    }
    handleGetInCartRecords(){
        this.showSpinner = true;
        getInCartProducts()
        .then (result => {
            this.inCartList = result.productWrapperList;
            if(this.inCartList.length > 0){
                this.showCart = true;
            } 
            this.totalCost = result.productTotalPrice;
            this.cartItemCount = result.productTotalQuantity; 
            this.showSpinner = false;       
        })
        .catch(error => {
            console.error('Error occured while fetching In Cart records -> '+JSON.stringify(error));
            this.showSpinner = false;
        });
    }
    handleClearShowCart(){
        this.showCart = false;
    }
    //generic method for showing toast
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}