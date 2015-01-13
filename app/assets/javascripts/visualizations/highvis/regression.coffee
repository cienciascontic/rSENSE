###
  * Copyright (c) 2011, iSENSE Project. All rights reserved.
  *
  * Redistribution and use in source and binary forms, with or without
  * modification, are permitted provided that the following conditions are met:
  *
  * Redistributions of source code must retain the above copyright notice, this
  * list of conditions and the following disclaimer. Redistributions in binary
  * form must reproduce the above copyright notice, this list of conditions and
  * the following disclaimer in the documentation and/or other materials
  * provided with the distribution. Neither the name of the University of
  * Massachusetts Lowell nor the names of its contributors may be used to
  * endorse or promote products derived from this software without specific
  * prior written permission.
  *
  * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
  * ARE DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR
  * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
  * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
  * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
  * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
  * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
  * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
  * DAMAGE.
  *
###
$ ->
  if namespace.controller is "visualizations" and
  namespace.action in ["displayVis", "embedVis", "show"]

    # Regression Types
    # Regression functions are listed with their partial derrivitives, eg.
    #
    # [f(x,Ps), f(x,Ps) dPs[0], f(x,Ps) dPs[1] ,... , f(x,Ps) dPs[dPs.length]]
    window.globals ?= {}
    globals.REGRESSION ?= {}

    globals.REGRESSION.FUNCS = []
    globals.REGRESSION.DENORM_FUNCS = []

    globals.REGRESSION.LINEAR = globals.REGRESSION.FUNCS.length
    globals.REGRESSION.FUNCS.push [
      (x, P) -> P[0] + (x * P[1]),
      (x, P) -> 1,
      (x, P) -> x]

    globals.REGRESSION.QUADRATIC = globals.REGRESSION.FUNCS.length
    globals.REGRESSION.FUNCS.push [
      (x, P) -> P[0] + (x * P[1]) + (x * x * P[2])
      (x, P) -> 1
      (x, P) -> x
      (x, P) -> x * x]
    hypothesis = (x, P) -> 
      #console.log "P[3]x^3 + P[2]x^2 + P[1]x + P[0] = #{(x * x * x) * P[3] + (x * x) * P[2] + P[1] * x + P[0]}"
      P[0] + (x * P[1]) + (x * x * P[2]) + (x * x * x * P[3])
    globals.REGRESSION.CUBIC = globals.REGRESSION.FUNCS.length
    globals.REGRESSION.FUNCS.push [
      hypothesis, #(x, P) -> P[0] + (x * P[1]) + (x * x * P[2]) + (x * x * x * P[3]),
      (x, P) -> 1,
      (x, P) -> x,
      (x, P) -> x * x,
      (x, P) -> x * x * x]

    globals.REGRESSION.EXPONENTIAL = globals.REGRESSION.FUNCS.length
    globals.REGRESSION.FUNCS.push [
      (x, P) -> P[0] + Math.exp(P[1] * x + P[2]),
      (x, P) -> 1,
      (x, P) -> x * Math.exp(P[1] * x + P[2]),
      (x, P) -> Math.exp(P[1] * x + P[2])]

    globals.REGRESSION.LOGARITHMIC = globals.REGRESSION.FUNCS.length
    globals.REGRESSION.FUNCS.push [
      (x, P) -> P[0] + P[1] * Math.log(P[2] + x),
      (x, P) -> 1,
      (x, P) -> Math.log(x + P[2]),
      (x, P) -> P[1] / (P[2] + x)]

    globals.REGRESSION.NUM_POINTS = 200

    ###
    Calculates a regression and returns it as a highcharts series.
    ###
    globals.getRegression = (xs, ys, type, xBounds, seriesName, dashStyle) ->

      Ps = []
      func = globals.REGRESSION.FUNCS[type]
      console.log 'func'
      # Make an initial Estimate
      switch type

        when globals.REGRESSION.LINEAR
          Ps = [1,1]

        when globals.REGRESSION.QUADRATIC
          Ps = [1,1,1]

        when globals.REGRESSION.CUBIC
          Ps = [1,1,1,1]

        when globals.REGRESSION.EXPONENTIAL
          Ps = [1,1,1]

        when globals.REGRESSION.LOGARITHMIC
          # We want to avoid starting with a guess that takes the log of a negative number
          Ps = [1,1,Math.min.apply(null, xs) + 1]
      console.log Ps
      # Calculate the regression, and return a highcharts series object
      #mean = calculateMean(xs)
      #sigma = calculateStandardDev(xs, mean)

      # Get the new Ps
      [Ps, R2] = NLLS(func, normalizeData(xs), ys, Ps)
      console.log 'done'
      #denormFunc = globals.REGRESSION.DENORM_FUNCS[type]
      #Ps =
      #  func(Ps, mean, sigma) for func in denormFunc

      generateHighchartsSeries(Ps, R2, type, xBounds, seriesName, dashStyle)

    ###
    Returns a series object to draw on the chart canvas.
    ###
    generateHighchartsSeries = (Ps, R2, type, xBounds, seriesName, dashStyle) ->
      str = makeToolTip(Ps, R2, type, seriesName)
      #console.log Ps, R2, type, xBounds, seriesName, dashStyle
      # Left shift the input values to zero and adjust the Ps for the left shift
      #denormFunc = globals.REGRESSION.DENORM_FUNCS[type]
      #Ps =
      #  func(Ps, -1 * xBounds.dataMin, 1) for func in denormFunc
      #console.log data
      #console.log 'getting called'
      y = 0
      regData = []
      for i in [0..globals.REGRESSION.NUM_POINTS]
        console.log 'running'
        xv = (i / globals.REGRESSION.NUM_POINTS) #* ((normalizeData(xBounds.dataMax) - normalizeData(xBounds.dataMin)) + normalizeData(xBounds.dataMin))
        console.log 'done'
        yv = calculateRegressionPoint(Ps, xv, type)
        console.log 'wat'
        regData.push {x: xv * (xBounds.dataMax - xBounds.dataMin) + xBounds.dataMin, y: yv}
      console.log "regdata is: #{regData}"
      ret =
        name:
          id: ''
          group: seriesName
          regression:
            tooltip: str
        data: regData
        type: 'line'
        color: '#000'
        lineWidth: 2
        dashStyle: dashStyle
        showInLegend: 0
        marker:
          symbol: 'blank'
        states:
          hover:
            lineWidth: 4
      console.log ret
      return ret

    ###
    Uses the regression matrix to calculate the y value given an x value.
    ###
    calculateRegressionPoint = (Ps, x, type) ->
      console.log "vis space value is: #{globals.REGRESSION.FUNCS[type][0](x, Ps)}"
      console.log globals.REGRESSION.FUNCS[type][0]
      
      globals.REGRESSION.FUNCS[type][0](x, Ps)

    ###
    Returns tooltip description of the regression.
    ###
    makeToolTip = (Ps, R2, type, seriesName) ->

      # Format parameters for output
      Ps = Ps.map roundToFourSigFigs

      ret = switch type

        when globals.REGRESSION.LINEAR
          """
          <div class="regressionTooltip"> #{seriesName} </div>
          <br>
          <strong>
            f(x) = #{Ps[1]}x + #{Ps[0]}
          </strong>
          """
        when globals.REGRESSION.QUADRATIC
          """
          <div class="regressionTooltip"> #{seriesName} </div>
          <br>
          <strong>
            f(x) = #{Ps[2]}x<sup>2</sup> + #{Ps[1]}x + #{Ps[0]}
          </strong>
          """
        when globals.REGRESSION.CUBIC
          """
          <div class="regressionTooltip"> #{seriesName} </div>
          <br>
          <strong>
            f(x) = #{Ps[3]}x<sup>3</sup> + #{Ps[2]}x<sup>2</sup> + #{Ps[1]}x + #{Ps[0]}
          </strong>
          """
        when globals.REGRESSION.EXPONENTIAL
          """
          <div class="regressionTooltip"> #{seriesName} </div>
          <br>
          <strong>
            f(x) = e<sup>(#{Ps[1]}x + #{Ps[2]})</sup> + #{Ps[0]}
          </strong>
          """

        when globals.REGRESSION.LOGARITHMIC
          """
          <div class="regressionTooltip"> #{seriesName} </div>
          <br>
          <strong>
            f(x) = #{Ps[1]} ln(x + #{Ps[2]}) + #{Ps[0]}
          </strong>
          """

      ret += """
      <br>
      <strong> R <sup>2</sup> = </strong> #{roundToFourSigFigs R2}
      """

    ###
    Round the current float value to 4 significant figures.
    I keep this in a separate function because we weren't sure this was the best implemenation.
    ###
    roundToFourSigFigs = (float) ->
      return float.toPrecision(4)

    ###
    Calculates the jacobian of the given x over the given parameters using
    a set of partial derrivitive functions as given at the top of this file.
    ###
    jacobian = (func, xs, Ps) ->
      jac = []

      res = for x in xs
        for P,Pindex in Ps
          func[Pindex + 1](x, Ps)

    ###
    Newton-Gauss non-linear least squares regression using shift-cutting

      MAX_ITER       - Maximum number of iterations before termination.
      SHIFT_CUT_DOWN - Shift cut fraction used when divergence occurs.
      SHIFT_CUT_UP   - Fraction used to increase shift size if no divergence occurs.
      THRESH         - Threshold of error change, terminates algorithm early if met.

      func - Array of function, function to be fit followed by its partial derrivitives.
      xs   - Array of x values
      ys   - Array of y values (ground truth)
      Ps   - Array of initial parameter estimates.
    ###
    NLLS_MAX_ITER = 1000
    NLLS_SHIFT_CUT_DOWN = 0.9
    NLLS_SHIFT_CUT_UP = 1.1
    NLLS_THRESH = 1e-10
    NLLS = (func, xs, ys, Ps) ->
      console.log "NLLS!"
      prevErr = Infinity
      shiftCut = 1
      #console.log("TRAINING: x is #{xs}")
      for iter in [1..NLLS_MAX_ITER]
        # Iterate
        dPs = iterateNLLS(func, xs, ys, Ps)
        console.log 'back'
        nextPs = numeric.add(Ps, numeric.mul(dPs, shiftCut))
        nextErr = sqe(func, xs, ys, nextPs)

        if prevErr < nextErr or isNaN(nextErr)
          # If the iteration has diverged (or failed), line search a shift cut
          lsIters = 0
          while prevErr < nextErr or isNaN(nextErr)
            # If we line search too long and can't find a valid value
            # Then we declare the regression to have failed and throw.
            lsIters += 1
            #console.log 'could error'
            if lsIters > 500
              #console.log 'throwing error'
              throw new Error()

            shiftCut *= NLLS_SHIFT_CUT_DOWN
            nextPs = numeric.add(Ps, numeric.mul(dPs, shiftCut))
            nextErr = sqe(func, xs, ys, nextPs)
        else
          # Otherwise, accelerate towards optimum
          shiftCut = Math.min(shiftCut * NLLS_SHIFT_CUT_UP, 1)

        Ps = nextPs

        # Break early if the error ratio has dropped below the threshold
        if (prevErr - nextErr) / prevErr < NLLS_THRESH
          break

        prevErr = nextErr

      # Calculate R^2 value
      mean = numeric.sum(ys) / ys.length
      SStot = numeric.sum(ys.map((y) -> (y - mean) * (y - mean)))
      R2 = (1 - prevErr / SStot)

      [Ps, R2]

    ###
    Inner loop of Newton-gauss method
    ###
    iterateNLLS = (func, xs, ys, Ps) ->
      console.log 'where are we'
      residuals = numeric.sub(ys, xs.map((x) -> func[0](x, Ps)))
      console.log 'residuals'
      jac = jacobian(func, xs, Ps)
      console.log 'jacobian'
      jacT = numeric.transpose jac
      console.log "jacobian = #{jac}"
      console.log "jacobianT = #{jacT}"
      console.log "Residuals = #{residuals}"
      # dP = (JT*J)^-1 * JT * r
      deltaPs = numeric.dot(numeric.dot(numeric.inv(numeric.dot(jacT, jac)),
        jacT),
        residuals)
      console.log 'deltaPs'
      deltaPs

    ###
    Calculates the current squared error for the given function, parameters and ground truth.
    ###
    sqe = (func, xs, ys, Ps) ->
      numeric.sum(numeric.sub(ys, xs.map((x) -> func[0](x, Ps))).map (x) -> x * x)

    ###
    Denormalize functions given Ps, the mean and sigma.
    ###
    # Linear
    globals.REGRESSION.DENORM_FUNCS.push [
      (Ps, mean, sigma) -> Ps[0] - Ps[1] * mean / sigma,
      (Ps, mean, sigma) -> Ps[1] / sigma
    ]
    # Quadratic
    globals.REGRESSION.DENORM_FUNCS.push [
      (Ps, mean, sigma) ->
        globals.REGRESSION.DENORM_FUNCS[globals.REGRESSION.LINEAR][0](Ps, mean, sigma) \
        + (Ps[2] * Math.pow(mean, 2)) / Math.pow(sigma, 2)
      (Ps, mean, sigma) ->
        globals.REGRESSION.DENORM_FUNCS[globals.REGRESSION.LINEAR][1](Ps, mean, sigma) \
        - (Ps[2] * 2 * mean) / Math.pow(sigma, 2)
      (Ps, mean, sigma) -> (Ps[2] / Math.pow(sigma, 2))
    ]
    # Cubic
    globals.REGRESSION.DENORM_FUNCS.push [
      (Ps, mean, sigma) ->
        globals.REGRESSION.DENORM_FUNCS[globals.REGRESSION.QUADRATIC][0](Ps, mean, sigma) \
        - Ps[3] * Math.pow(mean, 3) / Math.pow(sigma, 3)
      (Ps, mean, sigma) ->
        globals.REGRESSION.DENORM_FUNCS[globals.REGRESSION.QUADRATIC][1](Ps, mean, sigma) \
        + Ps[3] * 3 * Math.pow(mean, 2) / Math.pow(sigma, 3)
      (Ps, mean, sigma) ->
        globals.REGRESSION.DENORM_FUNCS[globals.REGRESSION.QUADRATIC][2](Ps, mean, sigma) \
        - Ps[3] * 3 * mean / Math.pow(sigma, 3)
      (Ps, mean, sigma) -> Ps[3] / Math.pow(sigma, 3)
    ]
    # Exponential
    globals.REGRESSION.DENORM_FUNCS.push [
      (Ps, mean, sigma) -> Ps[0],
      (Ps, mean, sigma) -> Ps[1] / sigma,
      (Ps, mean, sigma) -> Ps[2] - (Ps[1] * mean) / sigma
    ]
    # Logarithmic
    globals.REGRESSION.DENORM_FUNCS.push [
      (Ps, mean, sigma) -> Ps[0] + Ps[1] * Math.log(1 / sigma),
      (Ps, mean, sigma) -> Ps[1],
      (Ps, mean, sigma) -> Ps[2] * sigma - mean
    ]

    # Calculate the average
    calculateMean = (points) ->
      mean = 0
      for point in points
        mean += point / points.length
      mean

    # Normalize
    normalizeData = (points) ->
      #(point - mean) / sigma for point in points
      max = Math.max.apply(null, points)
      min = Math.min.apply(null, points)
      #console.log "points is: #{points}"
      #console.log "max = #{max}, min = #{min}"
      #console.log (point - min) / (max - min) for point in points
      #console.log points.map((y) -> (y - min) / (max - min))
      points.map((y) -> (y - min) / (max - min))
    # Calculate the standard deviation
    calculateStandardDev = (points, mean) ->
      sigma = 0
      for point in points
        sigma += Math.pow(point - mean, 2)
      Math.sqrt( sigma / points.length )
