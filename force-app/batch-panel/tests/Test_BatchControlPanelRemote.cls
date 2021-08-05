/**
 * Created by Igor Malyuta on 04.08.2021.
 */
@IsTest
public with sharing class Test_BatchControlPanelRemote {

    private static final String TEST_BATCH_CONTROL_PANEL_REMOTE_BATCH_FAKE_ONE = 'Test_BatchControlPanelRemote.Batch_FakeOne';
    private static final String TEST_BATCH_CONTROL_PANEL_REMOTE_BATCH_FAKE_TWO = 'Test_BatchControlPanelRemote.Batch_FakeTwo';

    private static final List<ApexClass> FAKE_IMPLEMENTATIONS = new List<ApexClass>{
            new ApexClass(Name = TEST_BATCH_CONTROL_PANEL_REMOTE_BATCH_FAKE_ONE),
            new ApexClass(Name = TEST_BATCH_CONTROL_PANEL_REMOTE_BATCH_FAKE_TWO)
    };

    @TestSetup
    static void setup() {
        insert new Batch_Detail__c(
                Name = TEST_BATCH_CONTROL_PANEL_REMOTE_BATCH_FAKE_ONE,
                Interval_Mode__c = Batch_ScheduledAbstract.INTERVAL_MINUTES,
                Panel_Label__c = TEST_BATCH_CONTROL_PANEL_REMOTE_BATCH_FAKE_ONE,
                Relaunch_Interval__c = 30,
                Scope_Size__c = 200
        );
    }

    @IsTest
    static void getDataTest() {
        BatchControlPanelRemote.setMockImplementations(FAKE_IMPLEMENTATIONS);
        BatchControlPanelRemote.getData();
    }

    @IsTest
    static void getStateTest() {
        BatchControlPanelRemote.getState(getBatchDetail().Name);
    }

    @IsTest
    static void getStateFailTest() {
        try {
            BatchControlPanelRemote.getState(null);
        } catch (Exception e) {
        }
    }

    @IsTest
    static void relaunchBatchTest() {
        BatchControlPanelRemote.JobWrapper jobWrapper = BatchControlPanelRemote.getState(getBatchDetail().Name);
        jobWrapper.nextSchedule = Datetime.now().addMinutes(1);
        BatchControlPanelRemote.relaunchBatch(JSON.serialize(jobWrapper));
    }

    @IsTest
    static void relaunchBatchFailTest() {
        try {
            BatchControlPanelRemote.relaunchBatch(null);
        } catch (Exception e) {
        }
    }

    @IsTest
    static void addBatchTest() {
        Batch_Detail__c batchDetail = new Batch_Detail__c(
                Name = TEST_BATCH_CONTROL_PANEL_REMOTE_BATCH_FAKE_TWO,
                Interval_Mode__c = Batch_ScheduledAbstract.INTERVAL_HOURS,
                Panel_Label__c = TEST_BATCH_CONTROL_PANEL_REMOTE_BATCH_FAKE_TWO,
                Relaunch_Interval__c = 30,
                Scope_Size__c = 200
        );
        BatchControlPanelRemote.addBatch(batchDetail, false);
    }

    @IsTest
    static void addBatchFailsTest() {
        try {
            BatchControlPanelRemote.addBatch(null, false);
        } catch (Exception e) {
        }
    }

    @IsTest
    static void deleteBatchTest() {
        BatchControlPanelRemote.deleteBatch(getBatchDetail().Id);
    }

    @IsTest
    static void throwAuraExceptionTest() {
        try {
            BatchControlPanelRemote.throwAuraException(new BatchControlPanelRemote.BatchControlException());
        } catch (Exception e) {
        }
    }

    private static Batch_Detail__c getBatchDetail() {
        return getBatchDetail(TEST_BATCH_CONTROL_PANEL_REMOTE_BATCH_FAKE_ONE);
    }

    private static Batch_Detail__c getBatchDetail(String name) {
        return [SELECT Name, Interval_Mode__c, Panel_Label__c, Relaunch_Interval__c, Scope_Size__c FROM Batch_Detail__c WHERE Name =:name].get(0);
    }

    public class Batch_FakeOne extends Batch_ScheduledAbstract {

        public Database.QueryLocator start(Database.BatchableContext param1) {
            return Database.getQueryLocator('SELECT Id FROM Account');
        }

        public void execute(Database.BatchableContext bc, List<Object> accounts) {
            //Some logic here
        }

        public override Type getType() {
            return Batch_FakeOne.class;
        }

        public override void finalAction() {
            System.debug('Some action...');
        }
    }

    public class Batch_FakeTwo extends Batch_ScheduledAbstract {

        public Database.QueryLocator start(Database.BatchableContext param1) {
            return Database.getQueryLocator('SELECT Id FROM Account');
        }

        public void execute(Database.BatchableContext bc, List<Object> accounts) {
            //Some logic here
        }

        public override Type getType() {
            return Batch_FakeTwo.class;
        }

        public override void finalAction() {
            System.debug('Some action...');
        }
    }
}