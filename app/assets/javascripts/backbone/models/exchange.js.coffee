class Sugar.Models.Exchange extends Backbone.Model
  paramRoot: 'exchange'

  idAttribute: "id"

  defaults:
    title: ''
    poster_id: false
    last_poster_id: false
    posts_count: false

  urlRoot: ->
    '/discussions'

  editUrl: ->
    this.url() + '/edit'

  postsCountUrl: (options) ->
    options ||= {}
    if options.timestamp
      this.url() + '/posts/count.json?' + new Date().getTime()
    else
      this.url() + '/posts/count.json'


class Sugar.Collections.Discussions extends Backbone.Collection
  model: Sugar.Models.Discussion
  url: '/discussions'
