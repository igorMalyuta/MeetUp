/**
 * Created by Igor Malyuta
 */

public without sharing class Batch_DemoWithError extends Batch_ScheduledAbstract{
    
    public class DemoBatchException extends Exception{}
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id FROM Account');
    }
    
    public void execute(Database.BatchableContext bc, List<Object> objects) {
        throw new DemoBatchException('Demo exception');
    }
    
    public override Type getType() {
        return Batch_DemoWithError.class;
    }
    
    public override virtual String getBatchDescription() {
        return 'This is demo batch with exception in execution method';
    }
    
    public override virtual String getRecommendedIntervalMode() {
        return INTERVAL_MINUTES;
    }
    
    public override virtual Integer getRecommendedRelaunchInterval() {
        return 5;
    }
    
    public override virtual Integer getRecommendedScopeSize() {
        return 100;
    }
}