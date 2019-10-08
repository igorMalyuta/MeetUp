/**
 * Created by Igor Malyuta on 02.10.2019.
 */

public without sharing class AuraExceptionHelper {

    public static Object throwException(Exception e){
        String errorMessage = e.getMessage() + '\n' + e.getStackTraceString();
        System.debug('THROW EXCEPTION: ' + errorMessage);
        Exception auraException = new AuraHandledException(errorMessage);
        auraException.setMessage(errorMessage);
        throw auraException;
    }
}