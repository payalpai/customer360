import { LightningElement, api } from 'lwc';
import getPriceBookRecords from '@salesforce/apex/LTNG_ProductCatalog_Controller.getPriceBookRecords';
import getProductsByPriceBook from '@salesforce/apex/LTNG_ProductCatalog_Controller.getProductsByPriceBook';

export default class cmp_productCatalog extends LightningElement {
    selectedPricebook = '';
    options = [];
    productList = [];
    productListMaster = [];
    sortOptions = [
        {
            label : 'Name Ascending', value : 'productName-asc'
        },
        {
            label : 'Name Descending', value : 'productName-desc'
        },
        {
            label : 'Price Ascending', value : 'productListPrice-asc'
        },
        {
            label : 'Price Descending', value : 'productListPrice-desc'
        }
    ];
    @api accountId;

    @api
    get productValues() {
        return this.productList;
    }
    connectedCallback(){
        this.handleGetPriceBookRecords();
    }
    handleGetPriceBookRecords(){
        getPriceBookRecords({})
        .then (result => {
            this.options = result;
        })
        .catch(error => {
            console.error('Error occured while fetching PriceBook records -> '+JSON.stringify(error));
        });
    }
    handleChange(event) {
        this.selectedPricebook = event.detail.value;
        this.handleGetProductRecords();
    }
    handleGetProductRecords(){
        getProductsByPriceBook({ priceBookName : this.selectedPricebook})
        .then (result => {
            this.productList = this.productListMaster = result;           
        })
        .catch(error => {
            console.error('Error occured while fetching Product records -> '+JSON.stringify(error));
        });
    }
    handleKeyUp(event) {
        let searchData = this.productListMaster;
        let regex, searchText;
        
        searchText = event.target.value;
        
        if (searchText != null &&  searchText != "") {
            regex = new RegExp(searchText.replace(/[-[\]{}()*+?.,\\^$|#]/g, "\\$&"), "i");
            this.productList = searchData.filter(
              row =>
              regex.test(row.productName)
            );
        } 
        else {
            this.productList = searchData;
        }     
    }   
    handleSort(event){
        let sortOrder = event.detail.value;
        let sort = sortOrder.split('-');
        this.productList = this.sortData(this.productList, sort[0], sort[1]);
    }
    sortData(arr, key, direction) {
        let parseData = JSON.parse(JSON.stringify(arr));
        try {
            parseData.sort((a, b) => {
                
                let valueA;
                let valueB;
                if (typeof (a[key]) !== 'number' && typeof (b[key]) !== 'number') {
                    valueA = a[key] ? a[key].toLowerCase() : '';
                    valueB = b[key] ? b[key].toLowerCase() : '';
                }
                else {
                    valueA = a[key] ? a[key] : null;
                    valueB = b[key] ? b[key] : null;
                }
                if (valueA === valueB) return 0;
                if (valueA > valueB) return direction === 'desc' ? -1 : 1;
                if (valueA < valueB) return direction === 'desc' ? 1 : -1;
                return 0;
            });
        }
        catch (error) {
            console.error(error);
        }
        return parseData;
    }
    handleChangeInCart(event){
        const productList = event.detail;
        const selectedEvent = new CustomEvent('changeincart', { detail: productList });
        this.dispatchEvent(selectedEvent);
    }
}