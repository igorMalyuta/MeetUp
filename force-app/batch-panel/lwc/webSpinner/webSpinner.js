/**
 * Created by Igor Malyuta on 18.11.2019.
 */

import {LightningElement, api, track} from 'lwc';

export default class WebSpinner extends LightningElement {

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
        return 'rr-spinner ' + (this.showSpinner ? '' : ' hide ') + (this.fixed ? ' fixed ' : '');
    }
}