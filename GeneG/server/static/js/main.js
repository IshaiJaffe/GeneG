/**
 * Created by PyCharm.
 * User: ishai
 * Date: 12/12/11
 * Time: 13:17
 * To change this template use File | Settings | File Templates.
 */

var MAIN_CONTENT_ID = 'content';
var USER_LOGGED_IN_EXPIRE = 1000*60*1;
var current_user_id;

// standard read form to dict ( used for ajax post/put requests )
function make_dict_from_form(form_id)
{
    var dict = {};
    $('#' + MAIN_CONTENT_ID + ' #' + form_id + ' input,#dialogs_container #' + form_id + ' input').each( function()
    {
        var input = $(this);
        var type = input.attr('type');
        if(type == 'button' || type == 'submit')
            return;
        var name = input.attr('name');
        if(!name || name == '')
            return;
        if( type == 'checkbox')
            dict[name] = input.is(':checked') ? 'true' : 'false';
        else
        {
            if(input.hasClass('ghost_text'))
                dict[name] = '';
            else
                dict[name] = input.val();
        }
    });
    $('#' + MAIN_CONTENT_ID + ' #' + form_id + ' textarea,#dialogs_container #' + form_id + ' textarea').each( function()
    {
        var txt = $(this);
        var name = txt.attr('name');
        if(!name || name == '')
            return;
        if(txt.hasClass('ghost_text'))
            dict[name] = '';
        else
            dict[name] = txt.val();
    });
    $('#' + MAIN_CONTENT_ID + ' #' + form_id + ' select,#dialogs_container #' + form_id + ' select').each( function()
    {
        var sel = $(this);
        var name = sel.attr('name');
        if(!name || name == '')
            return;
        dict[name] = sel.val();
    })
    return dict;
}

function update_dict( old_dict, new_dict)
{
    for( var name in new_dict)
        old_dict[name] = new_dict[name];
}

function ajax_put(url, params, success, error)
{
    ajax_func(url,params,success,error,'PUT');
}


function ajax_delete(url, params, success, error)
{
    ajax_func(url,params,success,error,'DELETE');
}

function ajax_func(url,params,success,error,type)
{
    if(!error)
        error = function (xhr, msg,err)
        {
            alert(msg);
        }
    $.ajax( { url : url, data : params , type : type, success : success, error : error });
}

function is_me(user_id)
{
    return current_user_id && (Number(user_id) == Number(my_user_id));
}

function is_user_authenticated()
{
    return current_user_id ? true : false;
}


// checks for users online
function check_user_online(user_id)
{

}

function load_base_user_data(user_data)
{
    if(user_data)
    {
        current_user_id = user_data.id;
        init_user_push(user_data.id);
        // write user name and stuff

    }
}

// register for push messages
function init_user_push(user_id)
{

}