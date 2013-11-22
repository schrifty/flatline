window.Flatline ||= {}

$(document).ready ->

  # Sites: 1-5000
  # Users: 1-100000
  # Activities: 1-1M
  # Activity Rate: 1-1000?
  # Error Rate: 1-10000?


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

    # Activity Chart
    #   Users & Activities (axis 1)
    #   Site Count (axis 2)

      activityChart = $('#activity-chart').highcharts()
      activityChart.get('site-count').addPoint([ data.ts, data.stats.siteCount], true)
      activityChart.get('user-count').addPoint([ data.ts, data.stats.userCount], true)
      activityChart.get('activity-count').addPoint([ data.ts, data.stats.activityCount], true)

  $('#sender').on 'click', (event) ->
    Flatline.start()

Flatline.start = () ->
  $('#rate-chart').highcharts({
    chart: {
      type: 'line'
    },
    title: {
      text: 'Activity Rate v. Servers'
    },
    xAxis: {
      type: 'datetime'
    },
    yAxis: [{
      title: {
        id: 'rate-axis',
        text: 'Rate'
      }
    }, {
      opposite: true,
      title: {
        id: 'server-axis',
        text: 'Server Count'
      }
    }],
    series: [{
      data: [],
      id: 'activity-rate',
      name: 'Activity Rate'
    }, {
      data: [],
      id: 'error-rate',
      name: 'Error Rate'
    }, {
      data: [],
      id: 'app-server-count',
      name: 'App Servers',
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

  $('#activity-chart').highcharts({
    chart: {
      type: 'line'
    },
    title: {
      text: 'Activity v. Sites'
    },
    xAxis: {
      type: 'datetime'
    },
    yAxis: [{
      title: {
        id: 'activity-axis',
        text: 'Activities'
      }
    }, {
      opposite: true,
      title: {
        id: 'site-axis',
        text: 'Sites'
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
      name: 'Site Count',
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