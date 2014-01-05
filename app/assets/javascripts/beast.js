var TopicForm = {
  editNewTitle: function(txtField) {
    $('new_topic').innerHTML = (txtField.value.length > 5) ? txtField.value : 'New Topic';
  }
}

var LoginForm = {
  setToPassword: function() {
    $('openid_fields').hide();
    $('password_fields').show();
  },
  
  setToOpenID: function() {
    $('password_fields').hide();
    $('openid_fields').show();
  }
}

var PostForm = {
	postId: null,

	reply: Behavior.create({
		onclick:function() {
    	PostForm.cancel();
    	$('reply').toggle();
    	$('post_body').focus();
		}
	}),

	edit: Behavior.create(Remote.Link, {
		initialize: function($super, postId) {
			this.postId = postId;
			return $super();
		},
		onclick: function($super) {
			$('edit-post-' + this.postId + '_spinner').show();
			PostForm.clearPostId();
			return $super();
		}
	}),
	
	cancel: Behavior.create({
		onclick: function() { 
			PostForm.clearPostId(); 
			$('edit').hide()
			$('reply').hide()
			return false;
		}
	}),

  // sets the current post id we're editing
  editPost: function(postId) {
		this.postId = postId;
    $('post_' + postId + '-row').addClassName('editing');
		$('edit-post-' + postId + '_spinner').hide()
    if($('reply')) $('reply').hide();
		this.cancel.attach($('edit-cancel'))
		$('edit-form').observe('submit', function() { $('editbox_spinner').show() })
		setTimeout("$('edit_post_body').focus()", 250)
  },

  // checks whether we're editing this post already
  isEditing: function(postId) {
    if (PostForm.postId == postId.toString())
    {
      $('edit').show();
      $('edit_post_body').focus();
      return true;
    }
    return false;
  },

  clearPostId: function() {
    var currentId = PostForm.postId;
    if(!currentId) return;

    var row = $('post_' + currentId + '-row');
    if(row) row.removeClassName('editing');
		PostForm.postId = null;
  }
}

var RowManager = {
  addMouseBehavior : function(ele){
    ele.onmouseover = function(e){ 
      ele.addClassName('topic_over'); 
    }

    ele.onmouseout = function(e){
      ele.removeClassName('topic_over');
    }
  }
};


Event.addBehavior({
	'#search, #reply': function() { this.hide() },
	'#search-link:click': function() {
		$('search').toggle();
		$('search_box').focus();
		return false
	},
          
  'tr.forum' : function() {
    RowManager.addMouseBehavior(this);
  },
          
  'tr.topic' : function(){
    RowManager.addMouseBehavior(this);
  },

	'tr.post': function() {
		var postId = this.id.match(/^post_(\d+)-/)[1]
    var anchor = this.down(".edit a")
    if(anchor) { PostForm.edit.attach(anchor, postId) };
    RowManager.addMouseBehavior(this);
	},
	
	'#reply-link': function() {
		PostForm.reply.attach(this)
	},
	
	'#reply-cancel': function() {
		PostForm.cancel.attach(this)
	}
})

function fixRunIn() {
// work around lack of gecko support for display:run-in
  var re = /^num_|\s+num_|^un_|\s+un_|proof/;
  $$('div > h6').each(function(element) {
    next_p = element.next('p');
    if(re.test($(element.parentNode).className)) {
      var new_span = new Element('span').update(element.textContent);
      new_span.addClassName('theorem_label');
      var period = new Element('span').update('. ');
      if (next_p) {
        var next_el = next_p.firstChild;
        next_p.insertBefore(new_span, next_el);
        next_p.insertBefore(period, next_el);
        element.remove();
      } else {
        var p = new Element('p').update(new_span);
        p.appendChild(period);       
        element.replace(p);
      }
    } 
  });
// add tombstone to proof, since gecko doesn't support :last-child properly
 $$('div.proof').each(function(element) {
     var el = element.childElements()[element.childElements().length-1];
     var span = new Element('span').update('\u00a0\u00a0\u25ae');
     if (el.match('p')) {
       el.insert(span);
     } else {
       var par = new Element('p').update(span);
       par.addClassName('tombstone');
       element.appendChild(par);
     }
    });
}

function mactionWorkarounds() {
  $$('maction[actiontype="tooltip"]').each( function(mtool){
     Element.writeAttribute(mtool, 'title',
       Element.firstDescendant(mtool).nextSibling.firstChild.data);
     });
  $$('maction[actiontype="statusline"]').each( function(mstatus){
     var v = Element.firstDescendant(mstatus).nextSibling.firstChild.data;
     Event.observe(mstatus, 'mouseover', function(){window.status =  v;});
     Event.observe(mstatus, 'mouseout',  function(){window.status = '';});
     });
  $$('maction[actiontype="highlight"]').each( function(mhighlight){
     var elt = Element.firstDescendant(mhighlight);
     var a = mhighlight.getAttribute('other').split(/\s*=\s*/);
     var pp = /^.(#?\w+).$/.exec(a[1]);
     if (pp) var colspec = pp[1];
     switch (a[0]) {
       case 'color' :
         var oldColspec = window.getComputedStyle(elt, null).color;
         break;
       case 'background' :
         var oldColspec = window.getComputedStyle(elt, null).backgroundColor;
     }
     if (colspec && oldColspec) {
       Event.observe(mhighlight, 'mouseover', function(){elt.setAttribute('style', a[0]+':'+colspec);});
       Event.observe(mhighlight, 'mouseout',  function(){elt.setAttribute('style', a[0]+':'+oldColspec);});
     }
   });
}

function setupSVGedit(elt, path){
  var f = $('MarkupHelp');
  var selected;
  var before;
  var after;
// create a control button
  if (f) {
    var SVGeditButton = new Element('input', {id:'SVGeditButton', type:'button', value: 'Create an SVG graphic'});
    f.insert({top: SVGeditButton});
    SVGeditButton.disabled = true;
    Event.observe(SVGeditButton, 'click', function(){
      var editor = window.open(path, 'Edit SVG graphic', 'status=1,resizable=1,scrollbars=1');
      editor.addEventListener("load", function() {
        editor.svgEditor.setCustomHandlers({
            'save': function(window,svg){
               editor.svgEditor.setConfig({no_save_warning: true});
               window.opener.postMessage(svg, window.location.protocol + '//' + window.location.host);
               window.close();
            }
        });
        editor.svgEditor.randomizeIds();
        if (selected) editor.svgEditor.loadFromString(selected);
      }, true);
      SVGeditButton.disabled = true;
      SVGeditButton.value = 'Create SVG graphic';      
      editor.focus();
    });
  }   
  var t = elt;
  
  var callback = function(){
// This is triggered by 'onmouseup' events
    var sel = window.getSelection();
    var a = sel.anchorOffset;
    var f = sel.focusOffset;
// A bit of ugliness, because Gecko-based browsers
// don't support getSelection in textareas
    if (t.selectionStart ) {
      var begin = t.selectionStart;
      var end = t.selectionEnd;
    } else {
      if( a < f) {
        begin = a;
        end = f;
      } else {
        begin = f;
        end = a;
      }
    }
// finally, slice up the textarea content into before, selected, & after pieces
    before = t.value.slice(0, begin);
    selected = t.value.slice(begin, end);
    after = t.value.slice(end, t.value.length);
    if (selected && selected != '') {
      if ( selected.match(/^<svg(.|\n)*<\/svg>$/) && !selected.match(/<\/svg>(.|\n)/)) {
        SVGeditButton.disabled = false;
        SVGeditButton.value = 'Edit existing SVG graphic';
      } else {
        SVGeditButton.disabled = true;
      }
    } else {
      SVGeditButton.disabled = false;
      SVGeditButton.value = 'Create SVG graphic';      
    }
  }
  Event.observe(t, 'mouseup', callback );
  Event.observe(SVGeditButton, 'click', callback );
  var my_loc = window.location.protocol + '//' + window.location.host;
  Event.observe(window, "message", function(event){
    if(event.origin !== my_loc) { return;}
    t.value = before + event.data + after;
    t.focus();
    selectRange(t, before.length, before.length+event.data.length);
    callback();      
  });  
}

function selectRange(elt, start, end) { 
 if (elt.setSelectionRange) { 
  elt.focus(); 
  elt.setSelectionRange(start, end); 
 } else if (elt.createTextRange) { 
  var range = elt.createTextRange(); 
  range.collapse(true); 
  range.moveEnd('character', end); 
  range.moveStart('character', start); 
  range.select(); 
 } 
}

function retrieveTexSource() {
	$$('math').each( function(math){Event.observe(math, 'dblclick', grabTex);} );
	function grabTex(event){
		var tex = this.firstElementChild.lastElementChild.textContent;
		var win= window.open('','TeX','scrollbars,resizable,width=500,location=no,toolbar=no,titlebar=no,menubar=no,personalbar=no');
		win.document.documentElement.lastElementChild.textContent = tex;
		win.focus();
	}
}
window.onload = function (){
        fixRunIn();
        mactionWorkarounds();
        retrieveTexSource();
        if ( $('monitor_submit') ) $('monitor_submit').hide();
};
