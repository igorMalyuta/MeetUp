/**
 * Created by Igor Malyuta on 03.10.2019.
 */

import {LightningElement, api, track} from 'lwc';

export default class UiSpinner extends LightningElement {

    //Attributes--------------------------------------------------------------------------------------------------------
    @api alternativeText = 'Processing...';
    @api fixed = false;
    @api size = 'medium';

    @track showSpinner = false;

    //Public methods----------------------------------------------------------------------------------------------------
    @api show() {
        this.showSpinner = true;
    }

    @api hide() {
        this.showSpinner = false;
    }

    //Expressions for html attributes-----------------------------------------------------------------------------------
    get cssClass() {
        return 'rr-spinner ' + (this.showSpinner ? '' : ' rr-hide ') + (this.fixed ? ' fixed ' : '');
    }
}