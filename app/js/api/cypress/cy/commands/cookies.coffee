$Cypress.register "Cookies", (Cypress, _, $) ->

  mergeDefaults = (obj) ->
    merge = (o) ->
      _.defaults o, {domain: window.location.hostname}

    if _.isArray(obj)
      _.map(obj, merge)
    else
      merge(obj)

  Cypress.on "test:before:hooks", ->
    @_automateCookies("get:cookies")
    .then (resp) =>
      cookies = Cypress.Cookies.getClearableCookies(resp)
      ## iterate over all of these and ensure none are whitelisted
      ## or preserved
      @_automateCookies("clear:cookies", cookies)

  Cypress.Cy.extend
    _automateCookies: (event, obj = {}, log) ->
      new Promise (resolve, reject) =>
        fn = (resp) =>
          if e = resp.__error
            err = @cypressErr(e)
            err.name = resp.__name
            err.stack = resp.__stack

            try
              @throwErr(err, log)
            catch e
              reject(e)
          else
            resolve(resp.response)

        Cypress.trigger(event, mergeDefaults(obj), fn)

  Cypress.addParentCommand
    getCookie: (name, options = {}) ->
      _.defaults options, {
        log: true
      }

      if options.log
        options._log = Cypress.Log.command({
          displayName: "get cookie"
          onConsole: ->
            obj = {}

            if c = options.cookie
              obj["Cookie"] = c
            else
              obj["Note"] = "No cookie with the name: '#{name}' was found."

            obj
        })

      if not _.isString(name)
        @throwErr("cy.getCookie() must be passed a string argument for name.", options._log)

      @_automateCookies("get:cookie", {name: name})
      .then (resp) ->
        options.cookie = resp

        return resp

    getCookies: (options = {}) ->
      _.defaults options, {
        log: true
      }

      if options.log
        options._log = Cypress.Log.command({
          displayName: "get cookies"
          onConsole: ->
            obj = {}

            if c = options.cookies
              obj["Returned"] = c
              obj["Num Cookies"] = c.length

            obj
        })

      @_automateCookies("get:cookies", {}, options._log)
      .then (resp) ->
        options.cookies = resp

        return resp

    setCookie: (name, value, options = {}) ->
      _.defaults options, {
        name: name
        value: value
        path: "/"
        secure: false
        httpOnly: false
        log: true
        # expiry: 123123123
      }

      cookie = _.pick(options, "name", "value", "path", "secure", "httpOnly", "expiry")

      if options.log
        options._log = Cypress.Log.command({
          displayName: "set cookie"
          onConsole: ->
            obj = {}

            if c = options.cookie
              obj["Returned"] = c

            obj
        })

      if not _.isString(name) or not _.isString(value)
        @throwErr("cy.setCookie() must be passed two string arguments for name and value.", options._log)

      @_automateCookies("set:cookie", cookie, options._log)
      .then (resp) ->
        options.cookie = resp

        return resp

    clearCookie: (name, options = {}) ->
      _.defaults options, {
        log: true
      }

      if options.log
        options._log = Cypress.Log.command({
          displayName: "clear cookie"
          onConsole: ->
            obj = {}

            if c = options.cookie
              obj["Cleared Cookie"] = c
            else
              obj["Note"] = "No matching cookie was found or cleared."

            obj
        })

      if not _.isString(name)
        @throwErr("cy.clearCookie() must be passed a string argument for name.", options._log)

      ## TODO: prevent clearing a cypress namespace
      @_automateCookies("clear:cookie", {name: name})
      .then (resp) ->
        options.cookie = resp

        ## null out the current subject
        return null

    clearCookies: (options = {}) ->
      _.defaults options, {
        log: true
      }

      if options.log
        options._log = Cypress.Log.command({
          displayName: "clear cookies"
          onConsole: ->
            obj = {}

            if c = options.cookies
              obj["Cleared Cookies"] = c
              obj["Num Cookies"] = c.length
            else
              obj["Note"] = "No cookies were found to be removed."

            obj
        })

      @_automateCookies("get:cookies")
      .then (resp) =>
        cookies = Cypress.Cookies.getClearableCookies(resp)
        ## iterate over all of these and ensure none are whitelisted
        ## or preserved
        @_automateCookies("clear:cookies", cookies)
      .then (resp) ->
        options.cookies = resp

        ## null out the current subject
        return null