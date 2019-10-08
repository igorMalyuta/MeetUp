/**
 * Created by Igor Malyuta on 30.05.2019.
 */

public with sharing class AdminPanelRemote {

    public class BatchException extends Exception {
    }

    public static final List<String> ASYNC_STATUSES = new List<String>{
            'Holding',
            'Queued',
            'Preparing',
            'Processing'
    };

    @AuraEnabled(Cacheable = true)
    public static String getData() {
        try {
           
    
            List<JobWrapper> jobWrappers = new List<JobWrapper>();
            

            return JSON.serialize(jobWrappers);
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

    @AuraEnabled
    public static JobWrapper getState(String jobName) {
        try {
            JobWrapper wrapper;
            for (JobWrapper jw : (List<JobWrapper>) JSON.deserialize(getData(), List<JobWrapper>.class)) {
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
        @AuraEnabled public Integer period;

        public JobWrapper(
                String s,
                Map<String, CronTrigger> scheduledBatches,
                Map<String, AsyncApexJob> asyncBatches,
                Map<String, AsyncApexJob> completedJobs,
                Map<String, AsyncApexJob> abortedJobs
        ) {
            this.jobName = '';
            this.label = '';
            this.period = 1;

            isStopped = true;
            if (completedJobs.containsKey(jobName)) {
                prevJob = completedJobs.get(jobName);
                prevLaunch = completedJobs.get(jobName).CompletedDate;
                Long prevExecutionMs = System.now().getTime() -  prevJob.CompletedDate.getTime();
                isStopped = prevExecutionMs > 30000;
            }

            if (asyncBatches.containsKey(jobName)) {
                css = 'ad-state-running';
                jobId = asyncBatches.get(jobName).Id;
                state = 'RUNNING';
                isStopped = false;
            } else if (scheduledBatches.containsKey(jobName)) {
                css = 'ad-state-running';
                jobId = scheduledBatches.get(jobName).Id;
                state = 'SCHEDULED';
                isStopped = false;
                nextLaunch = scheduledBatches.get(jobName).NextFireTime;
            } else if(abortedJobs.containsKey(jobName) || (completedJobs.isEmpty() && abortedJobs.isEmpty()) || isStopped){
                state = 'STOPPED';
                css = 'ad-state-stopped';
            } else {
                state = 'RUNNING';
                isStopped = false;
                css = 'ad-state-running';
            }
        }
    }
}