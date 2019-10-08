/**
 * Created by Leonid Bartenev
 */
({
    doShow: function (component) {
        component.set('v.showSpinner', true);
    },

    doHide: function (component) {
        component.set('v.showSpinner', false);
    }
})