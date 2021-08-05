## Batch Panel

##### 1. Create your own implementation of `Batch_ScheduledAbstract`.
```sh
public without sharing class Batch_ProcessActionSetupObjects extends Batch_ScheduledAbstract {}
```

##### 2. Then implement necessary methods: `start`, `execute`, `getType`, `getBatchDescription`
```sh
public without sharing class Batch_ProcessActionSetupObjects extends Batch_ScheduledAbstract{
    
    public Database.QueryLocator start(Database.BatchableContext param1) {
    }

    public void execute(Database.BatchableContext bc, List<Object> objects) {
    }
    
    public override Type getType() {
        return Batch_ProcessActionSetupObjects.class;
    }
    
    public override virtual String getBatchDescription() {
        return 'Your description for Batch Panel help text';
    }
}
```

##### 3. If you need execute some logic after all `execute` methods calls then use `finalAction` method.
```sh
public without sharing class Batch_ProcessActionSetupObjects extends Batch_ScheduledAbstract{
    
    public Database.QueryLocator start(Database.BatchableContext param1) {
    }

    public void execute(Database.BatchableContext bc, List<Object> objects) {
    }
    
    public override Type getType() {
        return Batch_ProcessActionSetupObjects.class;
    }
    
    public override virtual String getBatchDescription() {
        return 'Your description for Batch Panel help text';
    }

    public override virtual void finalAction() {
        //your logic
    }
}
```

##### 4. Also, you can suggest pre-setup for a batch, when it will add to the panel (interval mode, relaunch interval and scope size).
```sh
public without sharing class Batch_ProcessActionSetupObjects extends Batch_ScheduledAbstract{
    
    public Database.QueryLocator start(Database.BatchableContext param1) {
    }

    public void execute(Database.BatchableContext bc, List<Object> objects) {
    }
    
    public override Type getType() {
        return Batch_ProcessActionSetupObjects.class;
    }
    
    public override virtual String getBatchDescription() {
        return 'Your description for Batch Panel help text';
    }

    public override virtual String getRecommendedIntervalMode() {
        return INTERVAL_MINUTES;
    }
      
    public override virtual Integer getRecommendedRelaunchInterval() {
        return 2;
    }
    
    public override virtual Integer getRecommendedScopeSize() {
        return 10;
    }
}
```

### Please see guide for scratch org creation at path `doc/create-scratch-org.md` 