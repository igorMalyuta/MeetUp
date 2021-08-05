## Create Scratch Org Instruction

1) Login to DevHub if not logged in. Use your own developer account. In this account must be enabled dev hub feature. For enable Dev Hub got to Setup > Dev Hub

    ```
    sfdx force:auth:web:login -d -a devHubAlias
    ```

    If you already logged in to devhub you can set this devhub as default with command:

    ```
    sfdx force:config:set defaultdevhubusername=devHubAlias
    ```

2) Create Scratch Org

    ```
    sfdx force:org:create -f config/project-scratch-def.json -d 30 -s -a BatchPanelScratch
    ```

3) Push project to scratch org

    ```
    sfdx force:source:push
    ```

4) Assign Batch_Panel_Permission_Set on your user

   ````
   sfdx force:user:permset:assign -n Batch_Panel_Permission_Set
   ````

5) Apply scratch org in the IDE (Idea or Webstorm)

    ```
    File > Settings > Languages and frameworks > Illuminate Cloud (...) > Select in conection column "BatchPanelScratch"
    ```

6) You are ready for test or _Batch Control Panel_ in your scratch org!