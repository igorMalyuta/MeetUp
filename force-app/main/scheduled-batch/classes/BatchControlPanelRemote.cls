/**
 * Created by Igor Malyuta on 07.10.2019.
 */

public class BatchControlPanelRemote {

    public class BatchException extends Exception {}

    public static final String SCHEDULED_EXTENDS = 'extends Batch_ScheduledAbstract';
    public static final List<String> ASYNC_STATUSES = new List<String>{
            'Holding',
            'Queued',
            'Preparing',
            'Processing'
    };

    @AuraEnabled(Cacheable = true)
    public static String getData() {
        try {
            List<Batch_Detail__c> batchDetails = [
                    SELECT
                            Id,
                            Name,
                            Interval_Mode__c,
                            Relaunch_Interval__c,
                            Scope_Size__c
                    FROM Batch_Detail__c
                    ORDER BY Name
            ];
            List<String> panelBatchNames = new List<String>();
            for(Batch_Detail__c bc : batchDetails) panelBatchNames.add(bc.Name);

            List<ApexClass> batches = (List<ApexClass>) [FIND :SCHEDULED_EXTENDS IN ALL FIELDS RETURNING ApexClass(Id, Name)][0];
            List<String> batchNames = new List<String>();
            for (ApexClass batch : batches) {
                if(batch.Name.equals('BatchControlPanelRemote')) continue;
                batchNames.add(batch.Name);
            }

            PanelWrapper wrapper = new PanelWrapper();
            wrapper.availableBatches = new List<String>();
            for(String batchName : batchNames) {
                if(!panelBatchNames.contains(batchName) ) wrapper.availableBatches.add(batchName);
            }

            wrapper.intervalMods = new List<String>();
            for(PicklistEntry ple : Batch_Detail__c.Interval_Mode__c.getDescribe().getPicklistValues()){
                wrapper.intervalMods.add(ple.value);
            }

            wrapper.jobWrappers = (List<JobWrapper>) JSON.deserialize(getJobs(), List<JobWrapper>.class);
            return JSON.serialize(wrapper);
        } catch (Exception e) {
            return (String) AuraExceptionHelper.throwException(e);
        }
    }

    @AuraEnabled(Cacheable = true)
    public static String getJobs() {
        try {
            List<Batch_Detail__c> batchDetails = [
                    SELECT
                            Id,
                            Name,
                            Interval_Mode__c,
                            Panel_Label__c,
                            Relaunch_Interval__c,
                            Scope_Size__c
                    FROM Batch_Detail__c ORDER BY Name
            ];

            Map<String, Batch_Detail__c> batchMap = new Map<String, Batch_Detail__c>();
            for (Batch_Detail__c detail : batchDetails) batchMap.put(detail.Name, detail);

            List<AsyncApexJob> asyncApexJobs = [
                    SELECT
                            ApexClass.Name,
                            CompletedDate,
                            Status
                    FROM AsyncApexJob
                    WHERE JobType = 'BatchApex' AND Status IN:ASYNC_STATUSES
                    AND ApexClass.Name IN:batchMap.keySet()
            ];
            Map<String, AsyncApexJob> runningBatches = new Map<String, AsyncApexJob>();
            for (AsyncApexJob asyncApexJob : asyncApexJobs) runningBatches.put(asyncApexJob.ApexClass.Name, asyncApexJob);

            List<CronTrigger> cronTriggers = [
                    SELECT
                            CronJobDetail.Name,
                            NextFireTime
                    FROM CronTrigger
                    WHERE CronJobDetail.Name IN:batchMap.keySet()
            ];
            Map<String, CronTrigger> scheduledBatches = new Map<String, CronTrigger>();
            for (CronTrigger ct : cronTriggers) scheduledBatches.put(ct.CronJobDetail.Name, ct);

            Map<String, AsyncApexJob> completedJobs = new Map<String, AsyncApexJob>();
            for (AsyncApexJob aj : [
                    SELECT ApexClass.Name, CompletedDate, ExtendedStatus
                    FROM AsyncApexJob
                    WHERE Status = 'Completed'
                    AND ApexClass.Name IN:batchMap.keySet()
                    AND CompletedDate >=: System.now().addDays(-2)
                    ORDER BY CompletedDate DESC
            ]) {
                if(!completedJobs.containsKey(aj.ApexClass.Name)) completedJobs.put(aj.ApexClass.Name, aj);
            }

            Map<String, AsyncApexJob> abortedJobs = new Map<String, AsyncApexJob>();
            for (AsyncApexJob aj : [
                    SELECT ApexClass.Name, CompletedDate, ExtendedStatus
                    FROM AsyncApexJob
                    WHERE Status = 'Aborted'
                    AND ApexClass.Name IN: batchMap.keySet()
                    AND CompletedDate >=: System.now().addDays(-2)
                    ORDER BY CompletedDate DESC
            ]) {
                if(!abortedJobs.containsKey(aj.ApexClass.Name)) abortedJobs.put(aj.ApexClass.Name, aj);
            }

            List<JobWrapper> jobWrappers = new List<JobWrapper>();
            for (Batch_Detail__c detail : batchDetails) {
                jobWrappers.add(new JobWrapper(detail, scheduledBatches, runningBatches, completedJobs, abortedJobs));
            }

            return JSON.serialize(jobWrappers);
        } catch (Exception e) {
            return (String) AuraExceptionHelper.throwException(e);
        }
    }

    @AuraEnabled
    public static JobWrapper getState(String jobName) {
        try {
            JobWrapper wrapper;
            for (JobWrapper jw : (List<JobWrapper>) JSON.deserialize(getJobs(), List<JobWrapper>.class)) {
                if (jw.jobName.equals(jobName)) {
                    wrapper = jw;
                    break;
                }
            }
            if (wrapper == null) throw new BatchException('No batch found!');

            return wrapper;
        } catch (Exception e) {
            return (JobWrapper) AuraExceptionHelper.throwException(e);
        }
    }

    @AuraEnabled
    public static String addBatch(String apexClass, String label, String intervalMode, Integer interval, Integer scopeSize) {
        try {
            insert new Batch_Detail__c(
                    Name = apexClass,
                    Panel_Label__c = label,
                    Interval_Mode__c = intervalMode,
                    Relaunch_Interval__c = interval,
                    Scope_Size__c = scopeSize
            );
            return getData();
        } catch (Exception e) {
            return (String) AuraExceptionHelper.throwException(e);
        }
    }

    @AuraEnabled
    public static void runBatch(String jobName) {
        try {
            JobWrapper jobWrapper = getState(jobName);
            if (jobWrapper.jobId == null) {
                Database.executeBatch((Database.Batchable<SObject>) Type.forName(jobWrapper.jobName).newInstance());
            }
        } catch (Exception e) {
            AuraExceptionHelper.throwException(e);
        }
    }

    @AuraEnabled
    public static void stopBatch(String jobName) {
        try {
            JobWrapper jobWrapper = getState(jobName);
            if (jobWrapper.jobId != null) System.abortJob(jobWrapper.jobId);
        } catch (Exception e) {
            AuraExceptionHelper.throwException(e);
        }
    }

    public class JobWrapper {
        @AuraEnabled public String css;
        @AuraEnabled public String label;
        @AuraEnabled public String jobId;
        @AuraEnabled public String jobName;
        @AuraEnabled public AsyncApexJob prevJob;
        @AuraEnabled public Datetime prevLaunch;
        @AuraEnabled public Datetime nextLaunch;
        @AuraEnabled public String state;
        @AuraEnabled public Boolean isStopped;
        @AuraEnabled public String intervalMode;
        @AuraEnabled public Integer interval;

        public JobWrapper(
                Batch_Detail__c detail,
                Map<String, CronTrigger> scheduledBatches,
                Map<String, AsyncApexJob> asyncBatches,
                Map<String, AsyncApexJob> completedJobs,
                Map<String, AsyncApexJob> abortedJobs
        ) {
            this.jobName = detail.Name;
            this.label = detail.Panel_Label__c;
            this.intervalMode = detail.Interval_Mode__c;
            this.interval = (Integer) detail.Relaunch_Interval__c;

            isStopped = true;
            if (completedJobs.containsKey(jobName)) {
                prevJob = completedJobs.get(jobName);
                prevLaunch = completedJobs.get(jobName).CompletedDate;
                Long prevExecutionMs = System.now().getTime() -  prevJob.CompletedDate.getTime();
                isStopped = prevExecutionMs > 30000;
            }

            if (asyncBatches.containsKey(jobName)) {
                css = 'bcp-state-running';
                jobId = asyncBatches.get(jobName).Id;
                state = 'RUNNING';
                isStopped = false;
            } else if (scheduledBatches.containsKey(jobName)) {
                css = 'bcp-state-running';
                jobId = scheduledBatches.get(jobName).Id;
                state = 'SCHEDULED';
                isStopped = false;
                nextLaunch = scheduledBatches.get(jobName).NextFireTime;
            } else if(abortedJobs.containsKey(jobName) || (completedJobs.isEmpty() && abortedJobs.isEmpty()) || isStopped){
                state = 'STOPPED';
                css = 'bcp-state-stopped';
            } else {
                state = 'RUNNING';
                isStopped = false;
                css = 'bcp-state-running';
            }
        }
    }

    public class PanelWrapper {
        @AuraEnabled public List<String> availableBatches;
        @AuraEnabled public List<String> intervalMods;
        @AuraEnabled public List<JobWrapper> jobWrappers;
    }
}