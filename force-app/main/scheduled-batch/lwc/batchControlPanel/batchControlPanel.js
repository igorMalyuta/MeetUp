/**
 * Created by Igor Malyuta on 03.10.2019.
 */

import {LightningElement, track, wire} from 'lwc';
import {refreshApex} from '@salesforce/apex';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

import getData from '@salesforce/apex/BatchControlPanelRemote.getData';
import getJobs from '@salesforce/apex/BatchControlPanelRemote.getJobs';
import getState from '@salesforce/apex/BatchControlPanelRemote.getState';
import runBatch from '@salesforce/apex/BatchControlPanelRemote.runBatch';
import stopBatch from '@salesforce/apex/BatchControlPanelRemote.stopBatch';
import addBatch from '@salesforce/apex/BatchControlPanelRemote.addBatch';

export default class BatchControlPanel extends LightningElement {

    @track notAddedBatches;
    @track showAddNew;
    mods;
    @track jobs;
    @track initialized = false;
    @track inProcess = false;

    //Add new batch
    @track batchClass;
    @track batchLabel;
    @track batchIntervalMode;
    @track batchInterval;
    @track batchScopeSize;

    connectedCallback() {
        this.resetInputFields();
        let spinner;

        // setInterval(() => {
        //     if (!this.inProcess) {
        //         if (this.initialized) {
        //             if(!spinner) spinner = this.template.querySelector('c-ui-spinner');
        //
        //             this.inProcess = true;
        //             spinner.show();
        //             getData()
        //                 .then(data => {
        //                     let wrapper = JSON.parse(data);
        //                     this.notAddedBatches = wrapper.availableBatches;
        //                     this.showAddNew = this.notAddedBatches.length > 0;
        //                     this.mods = wrapper.intervalMods;
        //                     this.jobs = wrapper.jobWrappers.length > 0 ? wrapper.jobWrappers : undefined;
        //
        //                     this.inProcess = false;
        //                     if (spinner) spinner.hide();
        //                 })
        //                 .catch(error => {
        //                     console.log('Interval refresh error: ' + JSON.stringify(error));
        //                 });
        //         }
        //     }
        // }, 1500);
    }

    @wire(getData)
    wireData({error, data}) {
        if (data) {
            let wrapper = JSON.parse(data);
            this.notAddedBatches = wrapper.availableBatches;
            this.showAddNew = this.notAddedBatches.length > 0;
            this.mods = wrapper.intervalMods;
            this.jobs = wrapper.jobWrappers.length > 0 ? wrapper.jobWrappers : undefined;

            if (!this.initialized) this.initialized = true;
        }
    }

    // @wire(getJobs)
    // wireJobs({error, data}) {
    //     if (data) {
    //         if(!this.inProcess) this.jobs = JSON.parse(data);
    //     }
    // }

    //Select options: --------------------------------------------------------------------------------------------------
    get batchClasses() {
        let options = [];
        if (this.notAddedBatches) {
            this.notAddedBatches.forEach((name) => {
                options.push({
                    label: name,
                    value: name
                });
            });
        }
        return options;
    }

    get intervalMods() {
        let mods = [];
        if (this.mods) {
            this.mods.forEach((mod) => {
                mods.push({
                    label: mod,
                    value: mod
                });
            });
        }
        return mods;
    }

    //Handlers OnChange: -----------------------------------------------------------------------------------------------
    handleClassChange(event) {
        this.batchClass = event.target.value;
    }

    handleLabelChange(event) {
        this.batchLabel = event.target.value;
    }

    handleModeChange(event) {
        this.batchIntervalMode = event.target.value;
    }

    handleIntervalChange(event) {
        this.batchInterval = event.target.value;
    }

    handleScopeChange(event) {
        this.batchScopeSize = event.target.value;
    }

    //Handlers Remote: -------------------------------------------------------------------------------------------------
    handleRun(event) {
        let jobName = event.target.title;
        let spinner = this.template.querySelector('c-ui-spinner');
        spinner.show();
        this.inProcess = true;

        runBatch({jobName: jobName})
            .then(() => {
                this.waitStateChange(jobName, 'RUNNING,SCHEDULED', spinner, () => {
                    this.showToast('', 'Batch launched successfully!', 'success');
                });
            })
            .catch(error => {
                console.log('Error in: handleRun(' + jobName + ') ' + JSON.stringify(error));
            });
    }

    handleStop(event) {
        let jobName = event.target.title;
        let spinner = this.template.querySelector('c-ui-spinner');
        spinner.show();
        this.inProcess = true;

        stopBatch({jobName: jobName})
            .then(() => {
                this.waitStateChange(jobName, 'STOPPED', spinner, () => {
                    this.showToast('', 'Batch stopped successfully!', 'success');
                })
            })
            .catch(error => {
                console.log('Error in: handleStop(' + jobName + ') ' + JSON.stringify(error));
            })
    }

    handleAddBatch(event) {
        if (!this.batchClass || !this.batchLabel) {
            this.showToast('Failed', 'Please fill required fields');
            return;
        }

        this.inProcess = true;
        let spinner = this.template.querySelector('c-ui-spinner');
        spinner.show();

        addBatch({
            apexClass: this.batchClass,
            label: this.batchLabel,
            intervalMode: this.batchIntervalMode,
            interval: this.batchInterval,
            scopeSize: this.batchScopeSize
        })
            .then(data => {
                let wrapper = JSON.parse(data);
                this.notAddedBatches = wrapper.availableBatches;
                this.showAddNew = this.notAddedBatches.length > 0;
                this.mods = wrapper.intervalMods;
                this.jobs = wrapper.jobWrappers.length > 0 ? wrapper.jobWrappers : undefined;

                this.inProcess = false;
                this.resetInputFields();
            })
            .catch(error => {
                console.log('Error after add batch. ' + JSON.stringify(error));
            })
            .finally(() => {
                spinner.hide();
            })
    }

    //Service methods: -------------------------------------------------------------------------------------------------
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant === undefined ? 'info' : variant
        });
        this.dispatchEvent(event);
    }

    resetInputFields() {
        this.batchClass = undefined;
        this.batchLabel = undefined;
        this.batchIntervalMode = 'Minutes';
        this.batchInterval = 10;
        this.batchScopeSize = 200;
    }

    waitStateChange(jobName, waitedState, spinner, callback) {
        let context = this;

        getState({jobName: jobName})
            .then(wrapper => {
                if (waitedState.indexOf(wrapper.state) !== -1) {
                    let jobList = this.jobs;
                    for (let i = 0; i < jobList.length; i++) {
                        if (jobList[i].jobName === jobName) {
                            jobList[i] = wrapper;
                            break;
                        }
                    }
                    this.jobs = jobList;
                    spinner.hide();
                    this.inProcess = false;
                    callback();
                } else {
                    setTimeout(() => {
                        context.waitStateChange(jobName, waitedState, spinner, callback);
                    }, 500);
                }
            });
    }
}