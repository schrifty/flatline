// Generated by CoffeeScript 1.6.3
(function() {
  window.Flatline || (window.Flatline = {});

  $(document).ready(function() {
    this.started = false;
    io.connect().on("stats", function(data) {
      var actionChart, activityChart, rateChart, series, _i, _len, _ref;
      console.log(data);
      if (this.started || data.stats.activityRate > 0 || data.stats.errorRate > 0 || data.stats.userCount > 0 || data.stats.siteCount > 0) {
        this.started = true;
        rateChart = $('#rate-chart').highcharts();
        rateChart.get('app-server-count').addPoint([data.ts, data.stats.appServerCount], true);
        rateChart.get('job-server-count').addPoint([data.ts, data.stats.jobServerCount], true);
        rateChart.get('activity-rate').addPoint([data.ts, data.stats.activityRate], true);
        rateChart.get('error-rate').addPoint([data.ts, data.stats.errorRate], true);
        actionChart = $('#action-chart').highcharts();
        _ref = Object.keys(data.stats.runningAvgByType);
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          series = _ref[_i];
          if (!actionChart.get(series)) {
            actionChart.addSeries({
              data: [],
              id: series,
              name: series,
              visible: false
            });
          }
          actionChart.get(series).addPoint([data.ts, data.stats.runningAvgByType[series]]);
        }
        activityChart = $('#activity-chart').highcharts();
        activityChart.get('site-count').addPoint([data.ts, data.stats.siteCount], true);
        activityChart.get('user-count').addPoint([data.ts, data.stats.userCount], true);
        activityChart.get('activity-count').addPoint([data.ts, data.stats.activityCount], true);
        return activityChart.get('running-avg').addPoint([data.ts, data.stats.runningAvg], true);
      }
    });
    return $('#sender').on('click', function(event) {
      return Flatline.start();
    });
  });

  Flatline.start = function() {
    var data;
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
      yAxis: [
        {
          min: 0,
          title: {
            id: 'rate-axis',
            text: 'Transactions/sec'
          }
        }, {
          opposite: true,
          min: 0,
          title: {
            id: 'server-axis',
            text: 'Server Count'
          }
        }
      ],
      series: [
        {
          data: [],
          id: 'activity-rate',
          name: 'Activities/sec'
        }, {
          data: [],
          id: 'error-rate',
          name: 'Errors/sec'
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
        }
      ],
      plotOptions: {
        series: {
          marker: {
            enabled: false
          }
        }
      }
    });
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
      yAxis: [
        {
          min: 0,
          title: {
            id: 'activity-axis',
            text: 'Response Time'
          }
        }
      ],
      plotOptions: {
        series: {
          marker: {
            enabled: false
          }
        }
      }
    });
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
      yAxis: [
        {
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
        }
      ],
      series: [
        {
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
        }
      ],
      plotOptions: {
        series: {
          marker: {
            enabled: false
          }
        }
      }
    });
    data = {};
    return $.ajax('/run', {
      type: 'POST',
      data: data,
      error: function(jqXHR, textStatus, errorThrown) {
        return console.log(textStatus + " - " + errorThrown + " - " + JSON.stringify(jqXHR));
      }
    });
  };

}).call(this);
