import { LightningElement, api } from 'lwc';
import getInCartProducts from '@salesforce/apex/LTNG_ProductCatalog_Controller.getInCartProducts';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import addToCart from '@salesforce/apex/LTNG_ProductCatalog_Controller.addToCart';
import removeFromCart from '@salesforce/apex/LTNG_ProductCatalog_Controller.removeFromCart';
import placeOrder from '@salesforce/apex/LTNG_ProductCatalog_Controller.placeOrder';

export default class cmp_viewCart extends LightningElement {
    inCartList = [];
    totalCost = 0;
    cartItemCount = 0;
    showModal = false;
    @api accountId;
    @api selectedPricebook;

    connectedCallback(){
        this.handleGetInCartRecords();
    }

    handleGetInCartRecords(){
        this.showSpinner = true;
        getInCartProducts()
        .then (result => {
            this.inCartList = result.productWrapperList;
            this.totalCost = result.productTotalPrice;
            this.cartItemCount = result.productTotalQuantity; 
            this.showSpinner = false;       
        })
        .catch(error => {
            console.error('Error occured while fetching Product records -> '+JSON.stringify(error));
            this.showSpinner = false;
        });
    }
    handleClickPlaceOrderButton(){
        this.showModal = true;
    }
    handleCloseModal(){
        this.showModal = false;
    }
    handleQuantityChange(event){
        let quantityToUpdate = event.target.value;
        let addedToCartId = event.target.name;
        if(quantityToUpdate > 0){
            this.showSpinner = true;
            addToCart({productId : addedToCartId, quantitySelected : quantityToUpdate})
            .then(result => {
                if(result){
                    this.showToast('Added to Cart', 'Product Added To Cart Successfully.', 'success');
                    this.handleGetInCartRecords();
                    this.showSpinner = false;                  
                }
            })
            .catch(error => {
                console.error('Error occured while adding in cart records -> '+JSON.stringify(error));
                this.showSpinner = false;
            });
        }
    }
    handleRemoveFromCart(event){
        let addedToCartId = event.currentTarget.dataset.index;
        this.showSpinner = true;
        removeFromCart({productId : addedToCartId, removeAll : false})
        .then(result => {
            if(result){
                this.showToast('Removed from Cart', 'Product Removed from Cart Successfully.', 'success');
                this.handleGetInCartRecords();
                this.showSpinner = false;
            }
        })
        .catch(error => {
            console.error('Error occured while removing in cart records -> '+JSON.stringify(error));
            this.showSpinner = false;
        });
    }
    handleRemoveAllFromCart(){
        this.showSpinner = true;
        removeFromCart({productId : '', removeAll : true})
        .then(result => {
            if(result){
                this.showToast('Removed from Cart', 'Product(s) Removed from Cart Successfully.', 'success');
                this.inCartList = [];
                this.totalCost = 0;
                this.cartItemCount = 0;
                this.showSpinner = false;
            }
        })
        .catch(error => {
            console.error('Error occured while removing in cart records -> '+JSON.stringify(error));
            this.showSpinner = false;
        });
    }
    handlePlaceOrder(){
        this.showModal = false;
        this.showSpinner = true;
        if(!this.selectedPricebook){
            this.selectedPricebook = 'Dmart Pricebook';
        }
        placeOrder({placeOrderList : this.inCartList, accountId : this.accountId, selectedPricebook : this.selectedPricebook })
        .then (result => {
            if(result === 'error'){
                this.showToast('Unable to create order', 'We are unable to process your order currently. Please try after sometime.', 'error');
                this.showSpinner = false;
            }
            else{
                let message = result + 'You can track the status of your order in Orders Tab.';
                this.showToast('Order Created Successfully', message, 'success');
                this.showSpinner = false;
                this.handleRemoveAllFromCart();
                const selectedEvent = new CustomEvent('clearshowcart');
                this.dispatchEvent(selectedEvent);
            }
        })
        .catch(error => {
            console.error('Error occured while Creating Order records -> '+JSON.stringify(error));
        });
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