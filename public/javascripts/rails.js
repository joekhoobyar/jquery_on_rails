/*  Most of this originated from http://github.com/rails/jquery-ujs
 *  but a small portion came from http://gist.github.com/367883
 *  
 *  - Joe Khoobyar
 **/
(function($) {
  /*
   * 
   **/
  var cache = [];
  $.preloadImages = function() {
    var args_len = arguments.length;
    for (var i = args_len; i--;) {
      var cacheImage = document.createElement('img');
      cacheImage.src = arguments[i];
      cache.push(cacheImage);
    }
  }
  
  
  /*
   * Since jQuery doesn't really have an easy to use
   * reset function, this is to replicate $.clear();
   **/
  $.fn.clearForm = function() {
    return this.each(function() {
      var type = this.type, tag = this.tagName.toLowerCase();
      if (tag == 'form')
        return $(':input',this).clearForm();
      if (type == 'text' || type == 'password' || tag == 'textarea')
        this.value = '';
      else if (type == 'checkbox' || type == 'radio')
        this.checked = false;
      else if (tag == 'select')
        this.selectedIndex = -1;
    });
  }
})(jQuery);

jQuery(function ($) {
    var csrf_token = $('meta[name=csrf-token]').attr('content'),
        csrf_param = $('meta[name=csrf-param]').attr('content');

    $.fn.extend({
        /**
         * Triggers a custom event on an element and returns the event result
         * this is used to get around not being able to ensure callbacks are placed
         * at the end of the chain.
         *
         * TODO: deprecate with jQuery 1.4.2 release, in favor of subscribing to our
         *       own events and placing ourselves at the end of the chain.
         */
        triggerAndReturn: function (name, data) {
            var event = new jQuery.Event(name);
            this.trigger(event, data);

            return event.result !== false;
        },

        /**
         * Handles execution of remote calls firing overridable events along the way
         */
        callRemote: function () {
            var el      = this,
                data    = el.is('form') ? el.serializeArray() : [],
                method  = el.attr('method') || el.attr('data-method') || 'GET',
                url     = el.attr('action') || el.attr('href');

            // TODO: should let the developer know no url was found
            if (url !== undefined) {
                if (el.triggerAndReturn('ajax:before')) {
                    $.ajax({
                        url: url,
                        data: data,
                        dataType: 'script',
                        type: method.toUpperCase(),
                        beforeSend: function (xhr) {
                            xhr.setRequestHeader("Accept", "text/javascript");
                            el.trigger('ajax:loading', xhr);
                        },
                        success: function (data, status, xhr) {
                            el.trigger('ajax:success', [data, status, xhr]);
                        },
                        complete: function (xhr) {
                            el.trigger('ajax:complete', xhr);
                        },
                        error: function (xhr, status, error) {
                            el.trigger('ajax:failure', [xhr, status, error]);
                        }
                    });
                }

                el.trigger('ajax:after');
            }
        }
    });

    /**
     *  confirmation handler
     */
    $('a[data-confirm],input[data-confirm]').live('click', function () {
        var el = $(this);
        if (el.triggerAndReturn('confirm') && !confirm(el.attr('data-confirm')))
            return false;
    });

    /**
     * remote handlers
     */
    $('form[data-remote]').live('submit', function (e) {
        $(this).callRemote();
        e.preventDefault();
    });

    $('a[data-remote],input[data-remote]').live('click', function(e) {
        $(this).callRemote();
        e.preventDefault();
    });

    $('a[data-method]:not([data-remote])').live('click', function(e) {
        var link = $(this),
            href = link.attr('href'),
            method = link.attr('data-method'),
            form = $('<form method="post" action="'+href+'"/>'),
            metadata_input = '<input name="_method" value="'+method+'" type="hidden" />';
        if (csrf_param && csrf_token)
            metadata_input += '<input name="'+csrf_param+'" value="'+csrf_token+'" type="hidden" />';

        form.hide()
            .append(metadata_input)
            .appendTo('body');

        e.preventDefault();
        form.submit();
    });

    /**
     * disable-with handlers
     */
    $('form[data-remote]:has(input[data-disable-with])').live('ajax:before', function () {
        $('input[data-disable-with]', this).each(function () {
            var input = $(this);
            input.data('enable-with', input.val())
                 .attr('value', input.attr('data-disable-with'))
                 .attr('disabled', 'disabled');
        });
    }).live('ajax:after', function () {
        $('input[data-disable-with]', this).each(function () {
            var input = $(this);
            input.removeAttr('disabled')
                 .val(input.data('enable-with'));
        });
    });
});


