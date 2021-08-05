/**
 * Created by Igor Malyuta on 20.11.2019.
 *
 * WARNING: This Apex Class is part of a package ct-batch-panel. You'll lose any edits you make directly in the org if you reinstall or upgrade the package
 */

public without sharing class BatchControlPanelRemote {

    public class BatchControlException extends Exception {
    }

    private static final String STATE_RUNNING = 'RUNNING';
    private static final String STATE_SCHEDULED = 'SCHEDULED';
    private static final String STATE_STOPPED = 'STOPPED';
    private static final String CSS_RUNNING = 'bcp-state-running';
    private static final String CSS_STOPPED = 'bcp-state-stopped';

    public static final String SCHEDULED_EXTENDS = 'extends Batch_ScheduledAbstract';
    public static final List<String> ASYNC_STATUSES = new List<String>{
            'Holding',
            'Queued',
            'Preparing',
            'Processing'
    };

    private static Boolean useMocks = false;
    private static List<ApexClass> fakeClasses;

    public static void setMockImplementations(List<ApexClass> mockClasses) {
        if (mockClasses != null && !mockClasses.isEmpty()) {
            useMocks = true;
            fakeClasses = mockClasses;
        }
    }

    @AuraEnabled(Cacheable = true)
    public static PanelWrapper getData() {
        try {
            List<ApexClass> batches = getBatches();
            List<String> batchNames = new List<String>();
            for (ApexClass batch : batches) {
                if (batch.Name.equals('BatchControlPanelRemote') || !useMocks && (batch.Name.startsWith('Test_Batch'))) continue;
                batchNames.add(batch.Name);
            }

            List<Batch_Detail__c> batchDetails = [
                    SELECT Name
                    FROM Batch_Detail__c
                    ORDER BY Name
            ];
            List<String> panelBatchNames = new List<String>();
            for (Batch_Detail__c bc : batchDetails) panelBatchNames.add(bc.Name);

            PanelWrapper wrapper = new PanelWrapper();
            for (String batchName : batchNames) {
                if (!panelBatchNames.contains(batchName)) {
                    wrapper.availableBatches.add(batchName);
                    JobDefSettings defSettings = getDefSettings(batchName);
                    if (defSettings != null) wrapper.defaultSettings.add(defSettings);
                }
            }

            for (PicklistEntry ple : Batch_Detail__c.Interval_Mode__c.getDescribe().getPicklistValues()) {
                wrapper.intervalMods.add(ple.value);
            }

            wrapper.jobWrappers = getJobs();
            return wrapper;
        } catch (Exception e) {
            return (PanelWrapper) throwAuraException(e);
        }
    }

    @AuraEnabled
    public static List<JobWrapper> getJobs() {
        try {
            List<Batch_Detail__c> batchDetails = [
                    SELECT
                            Id,
                            Name,
                            Interval_Mode__c,
                            Panel_Label__c,
                            Relaunch_Interval__c,
                            Last_Duration_Min__c,
                            Scope_Size__c
                    FROM Batch_Detail__c
                    ORDER BY Name
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
                    AND JobType = 'BatchApex'
                    AND ApexClass.Name IN:batchMap.keySet()
                    AND CompletedDate >= :System.now().addDays(-2)
                    ORDER BY CompletedDate DESC
            ]) {
                if (!completedJobs.containsKey(aj.ApexClass.Name)) completedJobs.put(aj.ApexClass.Name, aj);
            }

            Map<String, AsyncApexJob> abortedJobs = new Map<String, AsyncApexJob>();
            for (AsyncApexJob aj : [
                    SELECT ApexClass.Name, CompletedDate, ExtendedStatus
                    FROM AsyncApexJob
                    WHERE Status = 'Aborted'
                    AND JobType = 'BatchApex'
                    AND ApexClass.Name IN:batchMap.keySet()
                    AND CompletedDate >= :System.now().addDays(-2)
                    ORDER BY CompletedDate DESC
            ]) {
                if (!abortedJobs.containsKey(aj.ApexClass.Name)) abortedJobs.put(aj.ApexClass.Name, aj);
            }

            List<JobWrapper> jobWrappers = new List<JobWrapper>();
            for (Batch_Detail__c detail : batchDetails) {
                jobWrappers.add(new JobWrapper(detail, scheduledBatches, runningBatches, completedJobs, abortedJobs));
            }

            return jobWrappers;
        } catch (Exception e) {
            return (List<JobWrapper>) throwAuraException(e);
        }
    }

    @AuraEnabled(Cacheable = false)
    public static JobWrapper getState(String jobName) {
        try {
            JobWrapper wrapper;
            for (JobWrapper jw : getJobs()) {
                if (jw.detail.Name.equals(jobName)) {
                    wrapper = jw;
                    break;
                }
            }
            if (wrapper == null) throw new BatchControlException('No batch found!');

            return wrapper;
        } catch (Exception e) {
            return (JobWrapper) throwAuraException(e);
        }
    }

    @AuraEnabled
    public static PanelWrapper addBatch(Batch_Detail__c detail, Boolean launchNow) {
        try {
            insert detail;
            if (launchNow) Database.executeBatch((Database.Batchable<SObject>) Type.forName(detail.Name).newInstance());

            return getData();
        } catch (Exception e) {
            return (PanelWrapper) throwAuraException(e);
        }
    }

    @AuraEnabled
    public static PanelWrapper deleteBatch(String detailId) {
        try {
            delete [SELECT Id FROM Batch_Detail__c WHERE Id = :detailId];

            return getData();
        } catch (Exception e) {
            return (PanelWrapper) throwAuraException(e);
        }
    }

    @AuraEnabled
    public static Boolean runBatch(String wrapper) {
        try {
            JobWrapper jobWrapper = (JobWrapper) JSON.deserialize(wrapper, JobWrapper.class);
            if (getState(jobWrapper.detail.Name).jobId == null) {
                if (jobWrapper.nextSchedule != null) {
                    Integer minutes = (Integer) (jobWrapper.nextSchedule.getTime() - Datetime.now().getTime()) / 60000;
                    if (minutes <= 0) return false;

                    System.scheduleBatch((Database.Batchable<SObject>)
                            Type.forName(jobWrapper.detail.Name).newInstance(),
                            jobWrapper.detail.Name,
                            minutes,
                            jobWrapper.detail.Scope_Size__c.intValue()
                    );
                } else {
                    Database.executeBatch(
                            (Database.Batchable<SObject>) Type.forName(jobWrapper.detail.Name).newInstance(),
                            jobWrapper.detail.Scope_Size__c.intValue()
                    );
                }
            }
            return true;
        } catch (Exception e) {
            return (Boolean) throwAuraException(e);
        }
    }

    @AuraEnabled
    public static void stopBatch(String jobName) {
        try {
            JobWrapper jobWrapper = getState(jobName);
            if (jobWrapper.jobId != null) System.abortJob(jobWrapper.jobId);
        } catch (Exception e) {
            throwAuraException(e);
        }
    }

    @AuraEnabled
    public static Boolean relaunchBatch(String wrapper) {
        try {
            JobWrapper jobWrapper = (JobWrapper) JSON.deserialize(wrapper, JobWrapper.class);
            stopBatch(jobWrapper.detail.Name);
            return runBatch(wrapper);
        } catch (Exception e) {
            return (Boolean) throwAuraException(e);
        }
    }

    private static List<ApexClass> getBatches() {
        if (useMocks) return fakeClasses;
        return (List<ApexClass>) [FIND :SCHEDULED_EXTENDS IN ALL FIELDS RETURNING ApexClass(Id, Name)][0];
    }

    private static JobDefSettings getDefSettings(String className) {
        JobDefSettings settings;
        try {
            Type bType = Type.forName(className);
            if (bType != null) {
                settings = new JobDefSettings();
                settings.className = className;
                Batch_ScheduledAbstract instance = (Batch_ScheduledAbstract) bType.newInstance();
                settings.intervalMode = instance.getRecommendedIntervalMode();
                settings.relaunchInterval = instance.getRecommendedRelaunchInterval();
                settings.scopeSize = instance.getRecommendedScopeSize();
            }
        } catch (Exception e) {
            throw new BatchControlException('Can\'t create instance of this type (' + className + ')');
        }

        return settings;
    }

    public class JobWrapper {
        @AuraEnabled public String css;
        @AuraEnabled public Batch_Detail__c detail;
        @AuraEnabled public String jobId;
        @AuraEnabled public AsyncApexJob prevJob;
        @AuraEnabled public Datetime prevLaunch;
        @AuraEnabled public Datetime nextLaunch;
        @AuraEnabled public Datetime nextSchedule;
        @AuraEnabled public String state;
        @AuraEnabled public Boolean isStopped;
        @AuraEnabled public String description;

        public JobWrapper(
                Batch_Detail__c detail,
                Map<String, CronTrigger> scheduledBatches,
                Map<String, AsyncApexJob> asyncBatches,
                Map<String, AsyncApexJob> completedJobs,
                Map<String, AsyncApexJob> abortedJobs
        ) {
            this.detail = detail;
            try {
                Type bType = Type.forName(detail.Name);
                if (bType != null) {
                    Batch_ScheduledAbstract instance = (Batch_ScheduledAbstract) bType.newInstance();
                    description = instance.getBatchDescription();
                }

            } catch (Exception e) {
            }

            isStopped = true;
            if (completedJobs.containsKey(detail.Name)) {
                prevJob = completedJobs.get(detail.Name);
                prevLaunch = completedJobs.get(detail.Name).CompletedDate;
                Long prevTime = 0;
                if (prevJob.CompletedDate != null) prevTime = prevJob.CompletedDate.getTime();
                Long prevExecutionMs = System.now().getTime() - prevTime;
                isStopped = prevExecutionMs > 30000;
            }

            if (asyncBatches.containsKey(detail.Name)) {
                css = CSS_RUNNING;
                jobId = asyncBatches.get(detail.Name).Id;
                state = STATE_RUNNING;
                isStopped = false;
            } else if (scheduledBatches.containsKey(detail.Name)) {
                css = CSS_RUNNING;
                jobId = scheduledBatches.get(detail.Name).Id;
                state = STATE_SCHEDULED;
                isStopped = false;
                nextLaunch = scheduledBatches.get(detail.Name).NextFireTime;
            } else if (abortedJobs.containsKey(detail.Name) || (completedJobs.isEmpty() && abortedJobs.isEmpty()) || isStopped) {
                state = STATE_STOPPED;
                css = CSS_STOPPED;
            } else {
                state = STATE_RUNNING;
                isStopped = false;
                css = CSS_RUNNING;
            }
        }
    }

    public class JobDefSettings {
        @AuraEnabled public String className;
        @AuraEnabled public String intervalMode;
        @AuraEnabled public Integer relaunchInterval;
        @AuraEnabled public Integer scopeSize;
    }

    public class PanelWrapper {
        @AuraEnabled public List<String> availableBatches = new List<String>();
        @AuraEnabled public List<JobDefSettings> defaultSettings = new List<JobDefSettings>();
        @AuraEnabled public List<String> intervalMods = new List<String>();
        @AuraEnabled public List<JobWrapper> jobWrappers;
    }

    @TestVisible
    private static Object throwAuraException(Exception e) {
        String errorMessage = e.getMessage() + '\n' + e.getStackTraceString();
        System.debug('THROW EXCEPTION: ' + errorMessage);
        Exception auraException = new AuraHandledException(errorMessage);
        auraException.setMessage(errorMessage);
        throw auraException;
    }
}