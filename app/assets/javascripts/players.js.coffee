# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

jQuery ->
  $('#allPlayers').dataTable( {
    "aLengthMenu": [[10, 25, 50, 100, -1], [10, 25, 50, 100, "All"]],
    "iDisplayLength": -1,
    "order": [[1, 'desc']],
    "aoColumns": [
        null,
        { "asSorting": [ "desc", "asc" ] },
        { "asSorting": [ "desc", "asc" ] },
        null,
        { "asSorting": [ "desc", "asc" ] },
        { "asSorting": [ "desc", "asc" ] },
        { "asSorting": [ "desc", "asc" ] },
        { "asSorting": [ "desc", "asc" ] },
        { "asSorting": [ "desc", "asc" ] },
        { "asSorting": [ "desc", "asc" ] },
        { "asSorting": [ "desc", "asc" ] },
        { "asSorting": [ "desc", "asc" ] },
        { "asSorting": [ "desc", "asc" ] },
        { "asSorting": [ "desc", "asc" ] },
        null,
        { "asSorting": [ "desc", "asc" ] },
        { "asSorting": [ "desc", "asc" ] },
        { "asSorting": [ "desc", "asc" ] },
        { "asSorting": [ "desc", "asc" ] },
        { "asSorting": [ "desc", "asc" ] },
    ]
  } )