/**
 * Created by Igor Malyuta on 03.10.2019.
 */

import {LightningElement, track, wire} from 'lwc';
import {NavigationMixin} from 'lightning/navigation';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

import getData from '@salesforce/apex/BatchControlPanelRemote.getData';
import getJobs from '@salesforce/apex/BatchControlPanelRemote.getJobs';
import getState from '@salesforce/apex/BatchControlPanelRemote.getState';
import runBatch from '@salesforce/apex/BatchControlPanelRemote.runBatch';
import stopBatch from '@salesforce/apex/BatchControlPanelRemote.stopBatch';
import deleteBatch from '@salesforce/apex/BatchControlPanelRemote.deleteBatch';
import addBatch from '@salesforce/apex/BatchControlPanelRemote.addBatch';

export default class BatchControlPanel extends NavigationMixin(LightningElement) {

    @track notAddedBatches;
    @track showAddNew;
    mods;
    @track jobs;
    @track initialized = false;
    @track inProcess = false;
    spinner;

    //Add new batch
    @track batchClass;
    @track batchLabel;
    @track batchIntervalMode;
    @track batchInterval;
    @track batchScopeSize;

    connectedCallback() {
        setInterval(() => {
            if (!this.inProcess) {
                if (this.initialized) {
                    if (this.spinner === undefined) this.spinner = this.template.querySelector('c-ui-spinner');

                    this.inProcess = true;
                    getJobs()
                        .then(data => {
                            let jobs = JSON.parse(data);
                            this.jobs = jobs.length > 0 ? jobs : undefined;

                            this.inProcess = false;
                        })
                        .catch(error => {
                            console.log('Interval refresh error: ' + JSON.stringify(error));
                        });

                }
            }
        }, 1500);
    }

    @wire(getData)
    wireData({data}) {
        if (data) {
            let wrapper = JSON.parse(data);
            this.notAddedBatches = wrapper.availableBatches;
            this.showAddNew = this.notAddedBatches.length > 0;
            this.mods = wrapper.intervalMods;
            this.jobs = wrapper.jobWrappers.length > 0 ? wrapper.jobWrappers : undefined;

            this.resetInputFields();
            if (!this.initialized) this.initialized = true;
        }
    }

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

    //Batch Action Handlers: -------------------------------------------------------------------------------------------
    handleRun(event) {
        let jobName = event.target.value;
        this.spinner.show();
        this.inProcess = true;

        runBatch({jobName: jobName})
            .then(() => {
                this.waitStateChange(jobName, 'RUNNING,SCHEDULED', this.spinner, () => {
                    this.showToast('', 'Batch launched successfully!', 'success');
                });
            })
            .catch(error => {
                console.log('Error in: handleRun(' + jobName + ') ' + JSON.stringify(error));
            });
    }

    handleStop(event) {
        let jobName = event.target.value;
        this.spinner.show();
        this.inProcess = true;

        stopBatch({jobName: jobName})
            .then(() => {
                this.waitStateChange(jobName, 'STOPPED', this.spinner, () => {
                    this.showToast('', 'Batch stopped successfully!', 'success');
                })
            })
            .catch(error => {
                console.log('Error in: handleStop(' + jobName + ') ' + JSON.stringify(error));
            });
    }

    handleDelete(event) {
        let detailId = event.target.value;
        this.spinner.show();
        this.inProcess = true;

        deleteBatch({detailId: detailId})
            .then(data => {
                let wrapper = JSON.parse(data);
                this.notAddedBatches = wrapper.availableBatches;
                this.showAddNew = this.notAddedBatches.length > 0;
                this.jobs = wrapper.jobWrappers.length > 0 ? wrapper.jobWrappers : undefined;

                this.inProcess = false;
            })
            .catch(error => {
                console.log('Error in deleteBatch. ' + JSON.stringify(error));
            })
            .finally(() => {
                this.spinner.hide();
            });
    }

    handleEditDetail(event) {
        let detailId = event.target.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: detailId,
                objectApiName: 'Batch_Detail__c',
                actionName: 'edit'
            },
        });
    }

    //Create Record Handlers: ------------------------------------------------------------------------------------------
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

    handleAddBatch(event) {
        if (!this.batchClass || !this.batchLabel) {
            this.showToast('Failed', 'Please fill required fields');
            return;
        }

        this.inProcess = true;
        this.spinner.show();

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
                this.jobs = wrapper.jobWrappers.length > 0 ? wrapper.jobWrappers : undefined;

                this.inProcess = false;
                this.resetInputFields();
            })
            .catch(error => {
                console.log('Error after add batch. ' + JSON.stringify(error));
            })
            .finally(() => {
                this.spinner.hide();
            });
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