(function($) {
  
	/*
	* Since jQuery doesn't really have an easy to use
	* reset function, this is to replicate $.clear();
	**/
	$.fn.clear = function() {
		return this.each(function() {
			var type = this.type, tag = this.tagName.toLowerCase();
			if (tag == 'form')
				$(':input',this).clear ();
			else if (type == 'text' || type == 'password' || tag == 'textarea')
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
        },
        
        /**
         * Creates and fills out a new form, using an anchor's href as the action URL.
         */
        applyToNewForm : function (options) {
			var link = $(this), elements = [], form = null;
			options = options || {};
			options.url = options.url || link.attr('href') || window.location.href;
        	if (link && options.url) {
				options.method = options.method || link.attr('data-method');
				if (options.method)
					elements.push ('<input name="_method" value="'+options.method+'" type="hidden" />');
				if (csrf_param && csrf_token)
					elements.push ('<input name="'+csrf_param+'" value="'+csrf_token+'" type="hidden" />');
			  return $('<form method="post"/>').hide().appendTo('body').applyToForm (elements, options);
			}
        },

        /**
         * Applies the given element list and options to this form.
         */
        applyToForm : function (elements, options) {
			var form = $(this);
			if (arguments.length < 3 && ! $.isArray (elements))
				{ options = elements; elements = null; }
			elements = elements || [];
			var url = options.url, params = options.parameters, method = options.method;
			if (! url && (! params || $.isEmptyObject (params)))
				return form;

			// STRING parameter :  HTTP GET parameters (query string fragment)
			if (typeof(params)=='string')
				url += (url.indexOf('?')<0 ? '?' : '&') + params;

			// OBJECT parameter :  HTTP POST variables (via hidden form elements)
			//   This feature converts values into hidden form inputs,
			//   flattening nested keys along the way.
			else if ($.isPlainObject(params)) {
				var key;

				$.each (params, function (subkey,subval) {
					if (key && typeof(subkey)=='string')
						subkey = key+'['+subkey+']';

					if (typeof(subval)!='string') {
						key = subkey;
						if ($.isPlainObject (subval) || $.isArray (subval))
							$.each (subval, arguments.callee);
					}
					else if (form[0].elements[subkey]) {
						$(form[0].elements[subkey]).val (subval);
					}
					else {
						elements.push ($('<input type="hidden"/>').attr({'name': subkey, 'value' : subval}));
					}
				});
			}

			// Finally, we can fill in the form and return it.
			for (var i = 0; i < elements.length; i++)
				form.append(elements[i]);
			if (url)
				form.attr('action', url);
			return form;
        }
    });

    /**
     *  confirmation handler
     */
    $('a[data-confirm],input[data-confirm]').live('click', function (e) {
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
        var form = $(this).applyToNewForm ();
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
            input.removeAttr('disabled').val(input.data('enable-with'));
        });
    });
});


