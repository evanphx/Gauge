// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

/*
$.fn.setupPanel = function(){
  var numPanels = $('div.panel').length;

  return $(this).each(function(){
    var panel = $(this);

    if (numPanels > 1)
      panel.addClass('additional');

  });
};


var updateBodyWidth = function(){
  var w = 0, num = 0;
  $('div.panel').each(function(){
    w += $(this).outerWidth();
    num += 1;
  });

  $('body').width(w + $(window).width()/2);
};

var scrollingTo = false;

var centerPanel = function(panel, to_top) {
  scrollingTo = true;

  var wasCentered = false;

  if (panel.hasClass('middle')) {
    wasCentered = true;
  } else {
    $('div.panel.middle').removeClass('middle');
    panel.addClass('middle');
  }

  var x = panel.position().left + panel.outerWidth()/2 - $(window).width()/2;
  var y = 0;
  var bottom = panel.position().top + panel.outerHeight();
  var link = panel.find('a.current');

  if (!to_top && link.length > 0 && !wasCentered)
    y = link.position().top - $(window).height()/2;

  if (y < 0) {
    y = 0;
    to_top = true;
  }

  // console.log([
  //   "position=",
  //   [panel.position().left, panel.position().top],
  //   " x/y=",
  //   [x, y],
  //   " offset=",
  //   [window.pageXOffset, window.pageYOffset]
  // ]);

  if (window.pageYOffset > bottom && !to_top && y == 0)
    to_top = true;

  var after = function(){
    scrollingTo = false;
  }

  if (!navigator.userAgent.match(/WebKit.*Mobile/)) {
    if (to_top || y > 0)
      $.scrollTo({left:x, top:y}, 'fast', {queue:false, onAfter:after});
    else
      $.scrollTo(x, 'fast', {axis:'x', onAfter:after});
  }
};

var findClosestPanel = function(){
  var left = window.pageXOffset;
  var closest = false;
  var showPanel = null;

  $('div.panel').each(function(){
    var panel = $(this);
    var pos = panel.position().left + panel.outerWidth()/2 - $(window).width()/2;
    var diff = Math.abs(pos - left);

    if (closest === false || diff < closest) {
      closest = diff;
      showPanel = panel;
    } else
      return false;
  });

  return showPanel;
};

$('ul.nav li a:not(.popout)').live('click', function(){
  var link = $(this);
  var nav = $(this).parents('ul.nav:first');
  nav.find('a.selected').removeClass('selected');
  $(this).addClass('selected');

  var panel = $(this).parents('div.panel:first');
  panel.nextAll('div.panel').remove();
  panel.find('> div.content').html('<center><img src="/images/spinner.gif" class="spinner"></center>');

  $.ajax({
    url: this.href,
    success: function(html){
      var newPanel = $(html);
      var hash = panel.attr('url') || '';
      var link_text = $.trim(link.text());

      panel.replaceWith(newPanel);

      var curr;
      if (link_text.match(/^group\s*by/))
        curr = '\\\\CHANGE=' + escape($.trim($('select.group_key').val()));
      else
        curr = '\\\\' + link.attr('href').replace(/^\/dump\/.+?\//,'');

      if (hash.indexOf(curr) == -1)
        newPanel.attr('url', hash + curr);
      else
        newPanel.attr('url', hash);

      newPanel.setupPanel();

      updateBodyWidth();
      centerPanel(newPanel, true);
    },
    cache: false
  });

  return false;
});

$('div.panel .content a:not(.facebox)').live('click', function(){
  var link = $(this);
  var curPanel = $(this).parents('div.panel:first');

  curPanel.find('a.current').removeClass('current');
  link.addClass('current');

  var panel = $('<div class="panel additional"><center><img src="/images/spinner.gif" class="spinner"></center></div>');
  curPanel.nextAll('div.panel').remove().end().after(panel);

  $.ajax({
    url: this.href,
    success: function(html){
      link.addClass('current');

      var newPanel = $(html);
      panel.replaceWith(newPanel);
      newPanel.setupPanel();

      updateBodyWidth();
      centerPanel(newPanel, true);
    },
    cache: false
  });

  return false;
});

$('div.panel ul.nav li.group select.group_key').live('change', function(){
  var select = $(this);
  var link = select.parents('a:first');
  link.attr('href', link.attr('href').replace(/group:[a-z]+/,'group:'+select.val()));
  link.click();
});

$('div#menubar select.collection').live('change', function(){
  var select = $(this);
  window.location = '/dump/' + select.val();
});

*/

/*
$(function(){
  $(window).keydown(function(e){
    if (e.which == 37 || e.which == 39)
      return false;
  });

  $(window).keyup(function(e){
    if (e.which == 37) {
      var panel = findClosestPanel();
      if (!panel)
        return false;

      var obj = panel.prev('div.panel');
      if (obj.length)
        centerPanel(obj);
      else
        centerPanel(panel);
      return false;

    } else if (e.which == 39) {
      var panel = findClosestPanel();
      if (!panel)
        return false;

      var obj = panel.next('div.panel');
      if (obj.length)
        centerPanel(obj);
      else
        centerPanel(panel);
      return false;
    }
  });

  var spinner = new Image();
  spinner.src = '/images/spinner.gif';

  var panel = $('div.panel')
  panel.setupPanel();

  var width = panel.outerWidth();
  $('body').css('marginLeft', ($(window).width()/2 - width/2) + 'px');
});
  */
