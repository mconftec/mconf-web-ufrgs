# Used to keep elements in the sidebar always visible when the page is scrolled.
#= require jquery/jquery.sticky

$ ->
  if isOnPage 'spaces', 'index'

    # how results are formatted in the filter by name
    format = (state) ->
      if state.public
        r = "<i class='icon-awesome icon-eye-open icon-mconf-space-public'></i>"
      else
        r = "<i class='icon-awesome icon-lock icon-mconf-space-private'></i>"
      "#{r}<a href='#{state.url}'>#{state.text}</a>"

    # redirects to the space when an item is selected
    $("#space_filter_text").on "change", (e) ->
      window.location = e.added.url if e.added?.url?

    $("#space_filter_text").select2
      minimumInputLength: 1
      placeholder: I18n.t('spaces.index.search.by_name.placeholder')
      formatNoMatches: (term) ->
        I18n.t('spaces.index.search.by_name.no_matches', { term: term })
      width: '250'
      formatResult: format
      formatSelection: format
      ajax:
        url: '/spaces/select.json'
        dataType: 'json'
        data: (term, page) ->
          q: term
        results: (data, page) ->
          results: data

    # hovering an space shows its description in the sidebar
    $(".space-item").hover ->

      # hide all descriptions and shows the selected
      hovered = "div#" + $(this).attr("name") + "-description"
      $("#space-description-wrapper div.content-block-middle").hide()
      $(hovered).show()

      # remove all 'selected' classes and adds only to the selected div
      $(".space-item.selected").removeClass("selected")
      $(this).addClass("selected")

      # updates the position of the description div
      $("#space-description-wrapper").sticky("update")

    # move the space description in the sidebar to be always in
    # the visible space of the page when the page is scrolled
    $("#space-description-wrapper").sticky
      topSpacing: 20
      bottomSpacing: 250