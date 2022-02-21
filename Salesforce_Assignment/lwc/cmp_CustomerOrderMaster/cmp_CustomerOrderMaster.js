import { LightningElement, api } from 'lwc';

export default class cmp_CustomerOrderMaster extends LightningElement {
    recordId = '0012w00000lEq0KAAS';
    theActiveTab = 'Browse Products';
    productList = [];
    selectedPricebook = 'Dmart Pricebook';
    get ordersTab(){
        if(this.theActiveTab === 'Orders'){
            return true;
        }
        return false;
    }
    get inCartTab(){
        if(this.theActiveTab === 'In Cart'){
            return true;
        }
        return false;
    }
    get wishlistTab(){
        if(this.theActiveTab === 'Wishlist'){
            return true;
        }
        return false;
    }
    get browseTab(){
        if(this.theActiveTab === 'Browse Products'){
            return true;
        }
        return false;
    }

    loadTabContent(event) {
        this.theActiveTab = event.target.value;
    }

    handleChangeInCart(event){
        const productList = event.detail;
    }

}