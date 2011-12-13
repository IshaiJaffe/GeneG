import random
from django.template.context import Context
from django.template.defaulttags import url

__author__ = 'ishai'

from django import template


def register_all():
    pass

register = template.Library()

class TextNode(template.Node):
    def __init__(self, str):
        self.str = '<%' + str + '%>'
    def render(self,context):
        return self.str

@register.tag
def t_if(parser,token):
    exp = token.split_contents()
    arg = exp[1]
    return TextNode(' %s ? ' % scope_var(arg))

def scope_var(var):
    return '(typeof(%s)=="undefined"?this.%s:%s)' % (var,var,var)

@register.tag
def t_else(parser,token):
    return TextNode(' : ')

@register.tag
def t_endif(parser,token):
    return TextNode(' ; ')

@register.tag
def t_var(parser,token):
    exp = token.split_contents()
    if len(exp) == 2:
        return TextNode('= %s ' % scope_var(exp[1]))
    else:
        return TextNode('= %s ? %s : %s ' % (scope_var(exp[1]),scope_var(exp[1]),scope_var(exp[2])))

@register.tag
def t_url(parser,token):
    exp = token.split_contents()
    new_content = exp[0] + ' ' + exp[1]
    args = {}
    arg_names = {}
    for i in range(len(exp)-2):
        argname = ''.join([random.choice('1234567890') for j in range(10)] ) # 'xp_tag_arg%d'% i
        args[argname] = '<%= this.' + exp[i+2] + ' %>'
        arg_names[argname] = argname
        new_content += ' ' + argname
    token.contents = new_content
    tagged =  url(parser,token)
    old_render = tagged.render
    def new_render(context):
        rendered = old_render(Context(arg_names))
        for arg in args:
            rendered = rendered.replace(arg,args[arg])
        return rendered
    tagged.render = new_render
    return tagged

@register.tag
def t_uri(parser,token):
    exp = token.split_contents()
    return TextNode('= encodeURIComponent(' + scope_var(exp[1]) + ') ')


@register.tag
def t_for(parser,token):
    exp = token.split_contents()
    arg = exp[1]
    collection = exp[2]
    index = 'tmpl_for_index'
    if len(exp) > 3:
        index = exp[3]

    return TextNode(' for(%s in %s) { var %s = %s[%s]; ' % (index,scope_var(collection),arg,scope_var(collection),index))

@register.tag
def t_for_index(parser,token):
    exp = token.split_contents()
    arg = ''
    if len(exp) > 1:
        arg = exp[1]
    return TextNode('= tmpl_for_index ')

@register.tag
def t_endfor(parser,token):
    return TextNode(' } ')

# TODO need to implement
@register.tag
def t_include(parser,token):
    pass
#    exp = token.split_contents()
#    sel = exp[1]
#    if len(exp) > 2:
#        data = '(%s)' % exp[2]
#    else:
#        data = ''
#    return TextNode('{{tmpl%s %s}}' % (data, sel))