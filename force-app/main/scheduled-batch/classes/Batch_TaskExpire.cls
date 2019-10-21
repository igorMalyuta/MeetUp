/**
 * Created by Igor Malyuta on 14.10.2019.
 */

public class Batch_TaskExpire extends Batch_ScheduledAbstract {

    public Database.QueryLocator start(Database.BatchableContext param1) {
        return Database.getQueryLocator([
                SELECT Id, Status
                FROM Task
                WHERE ActivityDate = TODAY
                AND Type = 'Call'
                AND Status != 'Expired'
        ]);
    }

    public void execute(Database.BatchableContext param1, List<Task> tasks) {
        for(Task t : tasks) t.Status = 'Expired';
        update tasks;
    }

    public override Type getType() {
        return Batch_TaskExpire.class;
    }
}
