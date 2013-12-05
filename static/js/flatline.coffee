window.Flatline ||= {}

$(document).ready ->

  # We get one message from the server every 10 seconds or so
  @started = false
  io.connect().on "stats", (data) ->
    console.log data

    # Rate Chart
    #   Activity Rate & Error Rate (axis 1)
    #   App & Job Server Count (axis 2)

    if @started || data.stats.activityRate > 0 || data.stats.errorRate > 0 || data.stats.userCount > 0 || data.stats.siteCount > 0
      @started = true
      rateChart = $('#rate-chart').highcharts()
      rateChart.get('app-server-count').addPoint([ data.ts, data.stats.appServerCount], true)
      rateChart.get('job-server-count').addPoint([ data.ts, data.stats.jobServerCount], true)
      rateChart.get('activity-rate').addPoint([ data.ts, data.stats.activityRate], true)
      rateChart.get('error-rate').addPoint([ data.ts, data.stats.errorRate], true)
      rateChart.get('sockets-in-use').addPoint([ data.ts, data.stats.socketsInUse], true)

      # Action Chart

      actionChart = $('#action-chart').highcharts()
      for series in Object.keys(data.stats.runningAvgByType)
        unless actionChart.get(series)
          actionChart.addSeries({
            data: [],
            id: series,
            name: series,
            visible: false
          })
        actionChart.get(series).addPoint([ data.ts, data.stats.runningAvgByType[series]])

      # Activity Chart
      #   Users & Activities (axis 1)
      #   Site Count (axis 2)

      activityChart = $('#activity-chart').highcharts()
      activityChart.get('site-count').addPoint([ data.ts, data.stats.siteCount], true)
      activityChart.get('user-count').addPoint([ data.ts, data.stats.userCount], true)
      activityChart.get('activity-count').addPoint([ data.ts, data.stats.activityCount], true)
      activityChart.get('running-avg').addPoint([ data.ts, data.stats.runningAvg], true)

  $('#sender').on 'click', (event) ->
    Flatline.start()

Flatline.start = () ->
  $('#rate-chart').highcharts({
    chart: {
      backgroundColor: '#FCFFC5',
      borderWidth: 3,
      type: 'line'
    },
    title: {
      text: 'Scaling Effectiveness'
    },
    xAxis: {
      type: 'datetime'
    },
    yAxis: [{
      min: 0,
      title: {
        id: 'rate-axis',
        text: 'Transactions/sec/server'
      }
    }, {
      opposite: true,
      min: 0,
      title: {
        id: 'server-axis',
        text: 'Server Count'
      }
    }],
    series: [{
      data: [],
      id: 'activity-rate',
      name: 'Activity per Server'
    }, {
      data: [],
      id: 'error-rate',
      name: 'Errors per Server'
    }, {
      data: [],
      id: 'app-server-count',
      name: 'App Servers',
      yAxis: 1
    }, {
      data: [],
      id: 'sockets-in-use',
      name: 'Sockets-in-use',
      yAxis: 1
    }, {
      data: [],
      id: 'job-server-count',
      name: 'Job Servers',
      yAxis: 1
    }],
    plotOptions: {
      series: {
        marker: {
          enabled: false
        }
      }
    }
  })

  $('#action-chart').highcharts({
    chart: {
      borderWidth: 3,
      backgroundColor: '#FCFFC5',
      type: 'line'
    },
    title: {
      text: 'Response Times By Activity Type'
    },
    xAxis: {
      type: 'datetime'
    },
    yAxis: [{
      min: 0,
      title: {
        id: 'activity-axis',
        text: 'Response Time'
      }
    }],
    plotOptions: {
      series: {
        marker: {
          enabled: false
        }
      }
    }
  })

  $('#activity-chart').highcharts({
    chart: {
      borderWidth: 3,
      backgroundColor: '#FCFFC5',
      type: 'line'
    },
    title: {
      text: 'Activity v. Response Time'
    },
    xAxis: {
      type: 'datetime'
    },
    yAxis: [{
      min: 0,
      title: {
        id: 'activity-axis',
        text: 'Activity Count'
      }
    }, {
      min: 0,
      opposite: true,
      title: {
        id: 'response-time-axis',
        text: 'Response Times'
      }
    }],
    series: [{
      data: [],
      id: 'user-count',
      name: 'User Count'
    }, {
      data: [],
      id: 'activity-count',
      name: 'Activity Count'
    }, {
      data: [],
      id: 'site-count',
      name: 'Site Count'
    }, {
      data: [],
      id: 'running-avg',
      name: 'Running Average Response',
      yAxis: 1
    }],
    plotOptions: {
      series: {
        marker: {
          enabled: false
        }
      }
    }
  })

  data = {}
  $.ajax '/run',
    type: 'POST',
    data: data,
    error: (jqXHR, textStatus, errorThrown) ->
      console.log textStatus + " - " + errorThrown + " - " + JSON.stringify(jqXHR)