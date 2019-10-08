/**
 * Created by Igor Malyuta on 04.10.2019.
 */

public without sharing class Batch_HappyBirthday extends Batch_ScheduledAbstract {

    public Database.QueryLocator start(Database.BatchableContext param1) {
        return Database.getQueryLocator([
                SELECT
                        Id,
                        Birthdate,
                        Email,
                        Name
                FROM Contact
                WHERE Birthdate = TODAY
        ]);
    }

    public void execute(Database.BatchableContext param1, List<Contact> contacts) {
        //Send email
    }

    public override Type getType() {
        return Batch_HappyBirthday.class;
    }
}