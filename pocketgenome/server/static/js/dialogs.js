function message_dialog(title, message,callback)
{
    template_dialog({template:'message_dialog', data: {title:title, message:message }, cancel:callback});
}
function question_dialog(title, message,params, cancel, approve)
{
    if(!params)
        params = {};
    params['title'] = title;
    params['message'] = message;
    template_dialog({template:'question_dialog', data:params, cancel:cancel, submit:approve });

}
function template_dialog(params)
{
    params = params || {};
    // defaults
    var args = {
    };
    for(var k in params)
        args[k] = params[k];

    var template = args['template'];
    var data = args['data'] || {};
    var load = args['load'];
    var cancel = args['cancel'];
    var submit = args['submit'];
    var locked = args['locked'];
    var dialog;

    function _close_no_event()
    {
        dialog.hide('fast', function () { dialog.remove(); });
        $('#gray_cover').hide('fast');
    };

    var _submit = function()
    {
        var ret = true;
        if(submit)
            ret = submit(dialog);
        if( ret != false)
            _close_no_event();
    };


    var _cancel = function()
    {
        var ret = true;
        if(cancel)
            ret = cancel(dialog);
        if(ret != false)
            _close_no_event();
    };

    function render_dialog()
    {
        if( template )
            return render_template(template,data);
        else
            return $('<div class="popup" style="height:200px; width:200px;"></div>');
    }

    var init = function()
    {
        dialog = $('#dialogs_container>.popup');
        if(!dialog.length)
        {
            dialog = render_dialog();
            dialog.css( { display:'none' } );
            dialog.appendTo('#dialogs_container');
        }
        else
        {
            dialog.empty();
            var new_dialog = render_dialog();
            dialog.append(new_dialog.html());
        }
        $('#gray_cover').css({ height:$('body').height()}).show('fast').unbind('click').click(function()
        {
            if(!locked)
                $('.dialog_close', dialog).click(_cancel);
        });

        var width = dialog.outerWidth();
        var height = dialog.outerHeight();
        var w = $(window);
        var top = w.height()/2 + w.scrollTop() - height/2;
        var left = w.width()/2 - width/2;
        dialog.css( { position:'absolute', left:left, top:top } );
        dialog.show('fast', function ()
        {
            if(load)
                load(dialog);
        });
        $('.dialog_close', dialog).click( _cancel);
        $('.dialog_submit', dialog).click( _submit);
    };
    init();
};


function please_login_dialog(callback, next)
{
    if(!next)
        next = window.location.href;
    template_dialog({ template: 'login_dialog', data: {next:next}, cancel: callback});
}

function dialog_loading( title,msg)
{
    if(!title)
        title = 'Processing';
    if(!msg)
        msg = 'Please wait while we\'re processing you\'re request';

//    var dialog = $('#dialogs_container>.popup');
//    if(!dialog.length)
//    {
//        open_dialog_from_template(null,{}, null, null, null);
//        var dialog = $('#dialogs_container>.popup');
//    }
//    var height = dialog.height();
//    var loading_div = '<div class="dialog_loading" style="height:' + height + 'px;" >' +
//        '<a href="#" class="close-btn dialog_close">&nbsp;</a>' +
//        '<h2>' + title + '</h2>' +
//        '<p id="upper_dialog_text">' +   msg +
//        '</p><img src="/media/images/loading.gif" /></div>';
//    dialog.html(loading_div);
    template_dialog({template:'dialog_loading',data: { message: msg, title:title}, locked:true});
}

function dialog_loading_done(title, msg, closing_function)
{
    if(!title)
        title = 'Done';
    if( !msg)
        msg = 'Done processing.';
    template_dialog({template:'loading_done', data:{title:title, message:msg}, cancel:closing_function});
//
//    var dialog = $('#dialogs_container>.popup');
//    var height = dialog.height();
//    var loading_done ='<div class="dialog_loading" style="height:' + height + 'px;" ><h2>' + title + '</h2>' +
//        '<p id="upper_dialog_text" style="height:' + ( height - 120) + 'px">' +   msg +
//        '</p><center><input class="continue-btn dialog_close" style="float:none;" onclick="close_dialog();" /></center></div>';
//    dialog.html(loading_done);
//    lock_dialog = false;
//    on_close_function = closing_function;
}
function dialog_loading_error(err1,err2,closing_function)
{
//    var title = 'Error';
//    var msg = '';
//    var dialog = $('#dialogs_container>.popup');
//    var height = dialog.height();
//    var loading_done ='<div class="dialog_loading" style="height:' + height + 'px;" ><h2>' + title + '</h2>' +
//        '<p id="upper_dialog_text">' +   msg +
//        '</p><a href="#" class="continue-btn dialog_close" onclick="close_dialog();">&nbsp;</a></div>';
//    dialog.html(loading_done);
//    lock_dialog = false;
//    on_close_function = closing_function;
}
