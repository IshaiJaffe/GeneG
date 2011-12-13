
// renders template with data, does common logic
function render_template(template, json)
{
    // render the template
    var template_elm = $('#hidden_templates_div #' + template);
    if(!template_elm.length)
        template_elm = $('head ' + template);
    var tmp = $(template_elm.jqote(json));
    // update checkboxes selected
    $('input[type=checkbox]', tmp).each( function()
    {
        var ck = $(this);
        if(ck.val().toLowerCase() == 'true')
            ck.attr('checked', 'checked');
    });
    // updates select list selected
    $('select', tmp).each(function()
    {
        var sel = $(this);
        if(sel.attr('name') && sel.attr('name') != '')
        {
            $('option[value=' + sel.attr('s_value') + ']',sel).attr('selected','selected');
        }
    });
    // init datepickers
  //  $('input[type=text].date_picker',tmp).datepicker({ inline: true, defaultDate:+2	});

    // init ghost texts
    $('.ghost_text', tmp).focus( function() {
        var ui = $(this);
        if(ui.val() == ui.attr('g_text'))
            ui.val('');
        ui.removeClass('ghost_text');
    }).blur( function ()
        {
            var ui = $(this);
            if(ui.val() == '')
            {
                ui.val(ui.attr('g_text'));
                ui.addClass('ghost_text');
            }
        }).each( function ()   {
            var ui = $(this);
            if(ui.val() == '')
                ui.val(ui.attr('g_text'));
            else
                ui.removeClass('ghost_text');
        });

    // init user online flags
    $('.user_online_flag', tmp).each(function()
    {
        var flag = $(this);
        var user_id = flag.attr('user_id');
        var callback = function(is_online)
        {
            if(is_online)
                flag.removeClass('offline').addClass('online').attr('title','Online');
            else
                flag.removeClass('online').addClass('offline').attr('title','Offline');
            setTimeout(function()
            {
                check_user_online(user_id, callback);
            },USER_LOGGED_IN_EXPIRE);
        };
        check_user_online(user_id,callback);
    });
    return tmp;
}

function render_append_template(params)
{
    params = params || {};
    // defaults
    var args = {
        params:{},
        appendTo:MAIN_CONTENT_ID
    };
    for(var key in params)
        args[key] = params[key];

    var template = args['template'];
    var url = args['url'];
    var request_params = args['params'] || {};
    var data = args['data'];
    var user_data;
    var prerender = args['prerender'];
    var success = args['success'];

    var appendTo = args.appendTo;
    var tmp;

    function render_and_append()
    {
        if(prerender)
            prerender(data);
        tmp = render_template(template,data);
        if(appendTo)
        {
            var cont = $('#' + appendTo);
            cont.empty();
            tmp.appendTo(cont);
        }
        if(success)
            success(tmp);
    }

    if(data)
        render_and_append();
    else
    {
        $.get(url, request_params,function(rsp)
        {
            data = rsp.objects ? rsp.objects : rsp;
            user_data = rsp.meta.user;
            if(typeof(user_data) == 'object')
                load_base_user_data(user_data);
            render_and_append()
        });
    }
    return tmp;
}

function format_time(time)
{
    var minutes = time.getMinutes();
    if (minutes < 10)
        minutes = "0" + minutes;
    return time.getHours() + ":" + minutes;
}

function to_url_date(datetime)
{
    return datetime.getFullYear()+'-'+(datetime.getMonth()+1)+'-'+datetime.getDate()+'-'+datetime.getHours()+'-'+datetime.getMinutes();
}
