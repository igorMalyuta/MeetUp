/**
 * Created by Igor Malyuta on 04.08.2021.
 */
@IsTest
public with sharing class Test_BatchScheduledAbstract {

    @TestSetup
    static void setup() {
        insert new Batch_Detail__c(
                Name = 'Test_BatchScheduledAbstract.Batch_ForTest',
                Interval_Mode__c = Batch_ScheduledAbstract.INTERVAL_MINUTES,
                Panel_Label__c = 'Test_BatchScheduledAbstract.Batch_ForTest',
                Relaunch_Interval__c = 1,
                Scope_Size__c = 200
        );
    }

    @IsTest
    static void abstractClassTest() {
        Batch_ScheduledAbstract batchForTest = new Batch_ForTest();
        System.assertEquals(Batch_ForTest.class, batchForTest.getType());
        System.assertEquals(null, batchForTest.getBatchDescription());
        System.assertEquals(Batch_ScheduledAbstract.INTERVAL_MINUTES, batchForTest.getRecommendedIntervalMode());
        System.assertEquals(10, batchForTest.getRecommendedRelaunchInterval());
        System.assertEquals(200, batchForTest.getRecommendedScopeSize());
        batchForTest.finish(null);
    }

    public class Batch_ForTest extends Batch_ScheduledAbstract {

        public Database.QueryLocator start(Database.BatchableContext param1) {
            return Database.getQueryLocator('SELECT Id FROM Account');
        }

        public void execute(Database.BatchableContext bc, List<Object> accounts) {
            //Some logic here
        }

        public override Type getType() {
            return Batch_ForTest.class;
        }

        public override void finalAction() {
            System.debug('Some action...');
        }
    }
}