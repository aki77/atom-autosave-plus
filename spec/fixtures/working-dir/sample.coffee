class Quicksort
  sort: (items) ->
    return items if items.length <= 1

    pivot = items.shift()
    left = []
    right = []

    # Comment in the middle (and add the word 'items' again)

    while items.length > 0
      current = items.shift()
      if current < pivot
        left.push(current)
      else
        right.push(current)

    sort(left).concat(pivot).concat(sort(right))

  noop: ->
    # just a noop

exports.modules = Quicksort
